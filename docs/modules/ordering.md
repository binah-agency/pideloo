# Módulo: Ordering

## Propósito
Orquestación de órdenes D2C, desde carrito hasta entrega, agregando demanda y optimizando fulfillment.

## Arquitectura

\`\`\`
┌─────────────────────────────────────────┐
│           ORDERING MODULE              │
├─────────────────────────────────────────┤
│  Application                            │
│  ├── Commands: CreateOrder, ConfirmOrder│
│  ├── Queries: GetOrder, TrackOrder        │
│  ├── Sagas: OrderProcessingSaga           │
│  └── Events: OrderCreated, OrderConfirmed │
├─────────────────────────────────────────┤
│  Domain                                 │
│  ├── Aggregates: Order                    │
│  ├── Entities: OrderItem, Delivery        │
│  ├── Value Objects: OrderStatus, Money    │
│  └── Services: DeliveryEstimator          │
├─────────────────────────────────────────┤
│  Infrastructure                         │
│  ├── Supabase: orders, order_items        │
│  ├── Queue: Order processing jobs         │
│  └── Realtime: Status updates             │
└─────────────────────────────────────────┘
\`\`\`

## Schema de Base de Datos

\`\`\`sql
-- Tabla: orders
create table orders (
  id uuid primary key default gen_random_uuid(),
  consumer_id uuid references users(id),
  status text check (status in (
    'cart', 'pending', 'confirmed', 'preparing', 
    'ready', 'in_transit', 'delivered', 'cancelled'
  )) default 'cart',
  
  -- Totales
  subtotal decimal(10,2) not null,
  delivery_fee decimal(10,2) default 0,
  discount decimal(10,2) default 0,
  total decimal(10,2) not null,
  
  -- Dirección
  delivery_address text not null,
  delivery_lat float,
  delivery_lng float,
  delivery_instructions text,
  
  -- Timing
  requested_delivery_at timestamptz,
  estimated_delivery_at timestamptz,
  actual_delivery_at timestamptz,
  
  -- Referido
  referrer_id uuid references users(id),
  commission_calculated boolean default false,
  
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Tabla: order_items
create table order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid references orders(id) on delete cascade,
  product_id uuid references products(id),
  supply_node_id uuid references profiles(id),
  
  quantity int not null check (quantity > 0),
  unit_price decimal(10,2) not null,
  total_price decimal(10,2) not null,
  
  status text default 'pending', -- pending, picked, packed, fulfilled
  
  allocated_at timestamptz,
  fulfilled_at timestamptz
);

-- Tabla: demand_bundles (para agregación)
create table demand_bundles (
  id uuid primary key default gen_random_uuid(),
  zone_hash text not null, -- geohash de zona
  product_id uuid references products(id),
  total_quantity int not null,
  consumer_count int not null,
  status text default 'open', -- open, closed, allocated
  created_at timestamptz default now(),
  closed_at timestamptz
);
\`\`\`

## Zod Schemas

\`\`\`typescript
// src/schemas/order.schema.ts
export const OrderStatusSchema = z.enum([
  'cart', 'pending', 'confirmed', 'preparing', 
  'ready', 'in_transit', 'delivered', 'cancelled'
]);

export const OrderItemSchema = z.object({
  productId: z.string().uuid(),
  quantity: z.number().int().positive(),
  unitPrice: z.number().positive(),
});

export const CreateOrderSchema = z.object({
  items: z.array(OrderItemSchema).min(1),
  deliveryAddress: z.string().min(10),
  deliveryLat: z.number().min(-90).max(90),
  deliveryLng: z.number().min(-180).max(180),
  requestedDeliveryAt: z.string().datetime().optional(),
  referrerCode: z.string().optional(), // Código de agente
});

export const CartSchema = z.object({
  items: z.array(z.object({
    productId: z.string().uuid(),
    name: z.string(),
    price: z.number().positive(),
    quantity: z.number().int().positive(),
    image: z.string().url().optional(),
  })),
  total: z.number().positive(),
});

export type OrderStatus = z.infer<typeof OrderStatusSchema>;
export type OrderItem = z.infer<typeof OrderItemSchema>;
export type CreateOrderInput = z.infer<typeof CreateOrderSchema>;
export type Cart = z.infer<typeof CartSchema>;
\`\`\`

## Zustand Stores

\`\`\`typescript
// src/stores/cart.store.ts (simplificado, ver mobile/src/stores/)
// src/stores/order.store.ts
interface OrderState {
  currentOrder: Order | null;
  orders: Order[];
  isCreating: boolean;
  trackingOrderId: string | null;
  trackingStatus: OrderStatus | null;
}

interface OrderActions {
  createOrder: (data: CreateOrderInput) => Promise<string>; // returns orderId
  fetchOrders: () => Promise<void>;
  trackOrder: (orderId: string) => void;
  cancelOrder: (orderId: string) => Promise<void>;
}

export const useOrderStore = create<OrderState & OrderActions>()(
  immer((set, get) => ({
    currentOrder: null,
    orders: [],
    isCreating: false,
    trackingOrderId: null,
    trackingStatus: null,

    createOrder: async (data) => {
      set((state) => { state.isCreating = true; });
      
      // 1. Validar
      const validated = CreateOrderSchema.parse(data);
      
      // 2. Crear en Supabase
      const { data: order, error } = await supabase
        .from('orders')
        .insert({
          consumer_id: useAuthStore.getState().user!.id,
          ...validated,
          status: 'pending',
        })
        .select()
        .single();
      
      if (error) throw error;
      
      // 3. Crear items
      await supabase.from('order_items').insert(
        validated.items.map((item) => ({
          order_id: order.id,
          ...item,
        }))
      );
      
      set((state) => {
        state.currentOrder = order;
        state.isCreating = false;
      });
      
      return order.id;
    },

    trackOrder: (orderId) => {
      set((state) => { state.trackingOrderId = orderId; });
      
      // Subscribe to realtime updates
      supabase
        .channel(\`order-\${orderId}\`)
        .on('postgres_changes', { event: 'UPDATE', schema: 'public', table: 'orders', filter: \`id=eq.\${orderId}\` }, (payload) => {
          set((state) => { state.trackingStatus = payload.new.status; });
        })
        .subscribe();
    },

    // ... más acciones
  }))
);
\`\`\`

## Saga: Order Processing

\`\`\`typescript
// src/modules/ordering/application/sagas/order-processing.saga.ts

@Injectable()
export class OrderProcessingSaga {
  constructor(
    private readonly eventBus: EventBus,
    private readonly supabase: SupabaseClient,
  ) {}

  @Saga()
  orderCreated = (events$: Observable<any>): Observable<ICommand> => {
    return events$.pipe(
      ofType(OrderCreatedEvent),
      delay(1000), -- Esperar 1s para posibles cancelaciones
      map((event) => new AllocateInventoryCommand(event.orderId)),
    );
  };

  @Saga()
  inventoryAllocated = (events$: Observable<any>): Observable<ICommand> => {
    return events$.pipe(
      ofType(InventoryAllocatedEvent),
      map((event) => new CalculateCommissionCommand(event.orderId)),
    );
  };

  @Saga()
  commissionCalculated = (events$: Observable<any>): Observable<ICommand> => {
    return events$.pipe(
      ofType(CommissionCalculatedEvent),
      map((event) => new NotifyAgentCommand(event.agentId, event.amount)),
    );
  };
}
\`\`\`

## API Endpoints

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| POST | /orders | Crear orden (checkout) |
| GET | /orders/:id | Detalle de orden |
| GET | /orders | Listar órdenes del usuario |
| GET | /orders/:id/track | Tracking en tiempo real |
| POST | /orders/:id/cancel | Cancelar orden |
| POST | /orders/:id/confirm | Confirmar orden (supply) |

## Flujos

### Checkout (Consumer)
1. App: \`useCartStore.getState().items\` → Validar \`CartSchema\`
2. App: Formulario dirección + tiempo preferido
3. API: \`CreateOrderSchema.parse()\` → Crear orden \`status='pending'\`
4. Saga: Disparar \`AllocateInventoryCommand\`
5. DB: Reservar inventario en \`inventory.reserved_quantity\`
6. App: Mostrar confirmación + pago

### Agregación de Demanda (Background)
1. Cron cada 15 min: Cerrar \`demand_bundles\` abiertos
2. Algoritmo: Agrupar órdenes por \`zone_hash\` + \`product_id\`
3. Optimización: Asignar a supply nodes por proximidad + capacidad
4. Notificación: Avisar a supply nodes de volumen esperado

### Fulfillment (Supply Node)
1. Notificación push: "Tienes 5 órdenes para preparar"
2. App Supply: Lista de \`order_items\` pendientes
3. Acción: Marcar "picked" → "packed" → "ready for pickup"
4. Realtime: Consumer ve progreso en tracking
