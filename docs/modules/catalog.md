# Módulo: Catalog

## Propósito
Catálogo virtual unificado que agrega inventarios de múltiples supply nodes, mostrando disponibilidad real y precios optimizados.

## Arquitectura

\`\`\`
┌─────────────────────────────────────────┐
│           CATALOG MODULE               │
├─────────────────────────────────────────┤
│  Application                            │
│  ├── Commands: CreateProduct, UpdateStock │
│  ├── Queries: ListProducts, GetProduct    │
│  └── Events: ProductCreated, StockChanged │
├─────────────────────────────────────────┤
│  Domain                                 │
│  ├── Entities: Product, Category          │
│  ├── Value Objects: SKU, Money, StockQty  │
│  └── Services: PricingOptimizer           │
├─────────────────────────────────────────┤
│  Infrastructure                         │
│  ├── Supabase: products, inventory        │
│  └── Search: Full-text + geospatial       │
└─────────────────────────────────────────┘
\`\`\`

## Schema de Base de Datos

\`\`\`sql
-- Tabla: products (SKU maestro Pideloo)
create table products (
  id uuid primary key default gen_random_uuid(),
  sku text unique not null,
  name text not null,
  description text,
  category_id uuid references categories(id),
  base_price decimal(10,2) not null,
  unit text not null, -- kg, unit, lt, etc
  images text[],
  attributes jsonb default '{}', -- {color, size, etc}
  tags text[],
  is_active boolean default true,
  created_at timestamptz default now()
);

-- Tabla: inventory (stock por supply node)
create table inventory (
  id uuid primary key default gen_random_uuid(),
  product_id uuid references products(id),
  supply_node_id uuid references profiles(id),
  quantity int not null check (quantity >= 0),
  reserved_quantity int default 0,
  available_quantity int generated always as (quantity - reserved_quantity) stored,
  price_override decimal(10,2), -- null = usar base_price
  last_updated timestamptz default now(),
  unique(product_id, supply_node_id)
);

-- Vista: available_products (para queries)
create view available_products as
select 
  p.*,
  i.supply_node_id,
  i.available_quantity,
  coalesce(i.price_override, p.base_price) as final_price,
  ST_Distance(
    i.geo_location,
    query_location -- parámetro
  ) as distance_km
from products p
join inventory i on p.id = i.product_id
where i.available_quantity > 0 and p.is_active = true;
\`\`\`

## Zod Schemas

\`\`\`typescript
// src/schemas/product.schema.ts
export const ProductSchema = z.object({
  id: z.string().uuid(),
  sku: z.string().min(3),
  name: z.string().min(2).max(200),
  description: z.string().max(2000).optional(),
  basePrice: z.number().positive(),
  unit: z.enum(['unit', 'kg', 'lt', 'mt', 'box']),
  images: z.array(z.string().url()).max(5),
  attributes: z.record(z.string()).optional(),
  isActive: z.boolean().default(true),
});

export const InventorySchema = z.object({
  productId: z.string().uuid(),
  supplyNodeId: z.string().uuid(),
  quantity: z.number().int().min(0),
  reservedQuantity: z.number().int().min(0).default(0),
  priceOverride: z.number().positive().optional(),
});

export const ProductSearchSchema = z.object({
  query: z.string().min(1).max(100),
  category: z.string().uuid().optional(),
  lat: z.number().min(-90).max(90),
  lng: z.number().min(-180).max(180),
  radiusKm: z.number().positive().max(50).default(5),
  maxPrice: z.number().positive().optional(),
  inStock: z.boolean().default(true),
  page: z.number().int().positive().default(1),
  limit: z.number().int().positive().max(50).default(20),
});

export type Product = z.infer<typeof ProductSchema>;
export type Inventory = z.infer<typeof InventorySchema>;
export type ProductSearch = z.infer<typeof ProductSearchSchema>;
\`\`\`

## Zustand Store

\`\`\`typescript
// src/stores/catalog.store.ts
interface CatalogState {
  products: Product[];
  selectedProduct: Product | null;
  searchResults: Product[];
  isLoading: boolean;
  filters: ProductSearch;
}

interface CatalogActions {
  search: (params: ProductSearch) => Promise<void>;
  selectProduct: (id: string) => void;
  updateFilters: (filters: Partial<ProductSearch>) => void;
  refreshAvailability: (productId: string) => Promise<void>;
}

export const useCatalogStore = create<CatalogState & CatalogActions>()(
  immer((set, get) => ({
    products: [],
    selectedProduct: null,
    searchResults: [],
    isLoading: false,
    filters: { query: '', lat: 0, lng: 0, radiusKm: 5, page: 1, limit: 20 },

    search: async (params) => {
      set((state) => { state.isLoading = true; });
      const { data } = await supabase.rpc('search_products', params);
      set((state) => {
        state.searchResults = data || [];
        state.isLoading = false;
      });
    },

    selectProduct: (id) => {
      const product = get().searchResults.find((p) => p.id === id);
      set((state) => { state.selectedProduct = product || null; });
    },

    updateFilters: (filters) => {
      set((state) => { state.filters = { ...state.filters, ...filters }; });
    },

    refreshAvailability: async (productId) => {
      const { data } = await supabase
        .from('inventory')
        .select('*')
        .eq('product_id', productId);
      // Update local state with fresh availability
    },
  }))
);
\`\`\`

## Funciones de Supabase (RPC)

\`\`\`sql
-- Búsqueda geoespacial de productos
create or replace function search_products(
  query_text text,
  user_lat float,
  user_lng float,
  radius_km float default 5,
  max_price float default null,
  category_filter uuid default null
)
returns table (
  product_id uuid,
  supply_node_id uuid,
  name text,
  final_price decimal,
  available_quantity int,
  distance_km float
) as \$\$
begin
  return query
  select 
    p.id as product_id,
    i.supply_node_id,
    p.name,
    coalesce(i.price_override, p.base_price) as final_price,
    i.available_quantity,
    ST_Distance(
      ST_SetSRID(ST_MakePoint(i.lng, i.lat), 4326)::geography,
      ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography
    ) / 1000 as distance_km
  from products p
  join inventory i on p.id = i.product_id
  where 
    p.name ilike '%' || query_text || '%'
    and i.available_quantity > 0
    and ST_DWithin(
      ST_SetSRID(ST_MakePoint(i.lng, i.lat), 4326)::geography,
      ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography,
      radius_km * 1000
    )
    and (max_price is null or coalesce(i.price_override, p.base_price) <= max_price)
    and (category_filter is null or p.category_id = category_filter)
  order by distance_km, final_price;
end;
\$\$ language plpgsql;
\`\`\`

## API Endpoints

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | /products | Listar con filtros (query, geo, price) |
| GET | /products/:id | Detalle de producto + availability |
| GET | /products/nearby | Productos disponibles cerca (geo) |
| POST | /products | Crear producto (supply only) |
| PUT | /products/:id/stock | Actualizar stock (supply only) |
| GET | /categories | Listar categorías |

## Flujos

### Búsqueda de Producto (Consumer)
1. App: Consumer abre app, geolocalización automática
2. Store: \`useCatalogStore.search({ query: '', lat, lng, radiusKm: 5 })\`
3. Supabase: RPC \`search_products\` con índice geoespacial
4. App: Lista de productos con "Disponible en 2h desde [tienda]"

### Actualización de Stock (Supply)
1. Supply Node: Scan de producto o selección manual
2. App: Formulario con Zod \`InventorySchema\`
3. API: Validación → Update \`inventory\` table
4. Realtime: Broadcast a consumers viendo ese producto
