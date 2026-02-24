# Módulo: Network

## Propósito
Gestión de la red de ingresos: referidos, comisiones, tiers, y escalabilidad de agentes.

## Arquitectura

\`\`\`
┌─────────────────────────────────────────┐
│           NETWORK MODULE               │
├─────────────────────────────────────────┤
│  Application                            │
│  ├── Commands: GenerateCode, Withdraw   │
│  ├── Queries: GetEarnings, GetNetwork   │
│  ├── Sagas: ReferralConversionSaga      │
│  └── Events: ReferralConverted, TierUp │
├─────────────────────────────────────────┤
│  Domain                                 │
│  ├── Entities: AgentNode, Commission    │
│  ├── Value Objects: Tier, ReferralCode  │
│  ├── Services: CommissionCalculator     │
│  └── Policies: TierUpgradePolicy        │
├─────────────────────────────────────────┤
│  Infrastructure                         │
│  ├── Supabase: agent_nodes, commissions │
│  ├── Queue: Commission payouts          │
│  └── Notifications: Earnings alerts     │
└─────────────────────────────────────────┘
\`\`\`

## Schema de Base de Datos

\`\`\`sql
-- Tabla: agent_nodes (red de agentes)
create table agent_nodes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references users(id) unique,
  
  -- Jerarquía
  parent_id uuid references agent_nodes(id),
  depth int default 0, -- 0 = root, 1 = directo, etc
  
  -- Identidad
  referral_code text unique not null,
  
  -- Progreso
  tier text default 'seed',
  total_earnings decimal(12,2) default 0,
  available_balance decimal(12,2) default 0,
  pending_balance decimal(12,2) default 0,
  
  -- Métricas
  direct_recruits int default 0,
  network_size int default 0, -- total en downline
  total_sales decimal(12,2) default 0,
  
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Tabla: commissions
create table commissions (
  id uuid primary key default gen_random_uuid(),
  
  -- Quién gana
  agent_id uuid references agent_nodes(id),
  
  -- De dónde viene
  source_type text check (source_type in ('sale', 'referral', 'network', 'bonus')),
  source_order_id uuid references orders(id),
  source_agent_id uuid references agent_nodes(id), -- para network bonus
  
  -- Cuánto
  amount decimal(10,2) not null,
  percentage decimal(5,2), -- % aplicado
  
  -- Estado
  status text default 'pending', -- pending, available, paid, cancelled
  available_at timestamptz, -- fecha de liberación
  
  created_at timestamptz default now()
);

-- Tabla: withdrawals (retiros)
create table withdrawals (
  id uuid primary key default gen_random_uuid(),
  agent_id uuid references agent_nodes(id),
  amount decimal(10,2) not null,
  method text check (method in ('bank_transfer', 'digital_wallet', 'cash')),
  status text default 'pending',
  processed_at timestamptz,
  created_at timestamptz default now()
);
\`\`\`

## Zod Schemas

\`\`\`typescript
// src/schemas/referral.schema.ts
export const ReferralCodeSchema = z.string().regex(/^[A-Z0-9]{6}$/);

export const CommissionSchema = z.object({
  id: z.string().uuid(),
  agentId: z.string().uuid(),
  sourceType: z.enum(['sale', 'referral', 'network', 'bonus']),
  amount: z.number().positive(),
  percentage: z.number().min(0).max(100),
  status: z.enum(['pending', 'available', 'paid', 'cancelled']),
  availableAt: z.string().datetime().optional(),
  createdAt: z.string().datetime(),
});

export const AgentNodeSchema = z.object({
  id: z.string().uuid(),
  userId: z.string().uuid(),
  parentId: z.string().uuid().optional(),
  depth: z.number().int().min(0),
  referralCode: ReferralCodeSchema,
  tier: z.enum(['seed', 'sprout', 'growth', 'harvest']),
  totalEarnings: z.number().min(0),
  availableBalance: z.number().min(0),
  networkSize: z.number().int().min(0),
});

export const WithdrawalSchema = z.object({
  amount: z.number().positive(),
  method: z.enum(['bank_transfer', 'digital_wallet', 'cash']),
});

export type Commission = z.infer<typeof CommissionSchema>;
export type AgentNode = z.infer<typeof AgentNodeSchema>;
\`\`\`

## Sistema de Tiers

| Tier | Requisito | Comisión Directa | Comisión Red | Beneficios |
|------|-----------|------------------|--------------|------------|
| **Seed** | Registro | 10% | 0% | Acceso básico |
| **Sprout** | 10 ventas / $500 | 12% | 2% L1 | Capacitación |
| **Growth** | 50 ventas / $3,000 | 15% | 3% L1, 1% L2 | Adelantos |
| **Harvest** | 200 ventas / $15,000 | 20% | 5% L1, 2% L2, 1% L3 | Equity |

## Zustand Store

\`\`\`typescript
// src/stores/network.store.ts
interface NetworkState {
  myNode: AgentNode | null;
  commissions: Commission[];
  network: AgentNode[];
  earningsHistory: { date: string; amount: number }[];
  isLoading: boolean;
}

interface NetworkActions {
  generateReferralCode: () => Promise<string>;
  fetchEarnings: () => Promise<void>;
  fetchNetwork: () => Promise<void>;
  withdraw: (amount: number, method: string) => Promise<void>;
  recruitAgent: (email: string) => Promise<void>;
}

export const useNetworkStore = create<NetworkState & NetworkActions>()(
  immer(
    persist(
      (set, get) => ({
        myNode: null,
        commissions: [],
        network: [],
        earningsHistory: [],
        isLoading: false,

        generateReferralCode: async () => {
          const code = Math.random().toString(36).substring(2, 8).toUpperCase();
          await supabase.from('agent_nodes').update({ referral_code: code });
          return code;
        },

        fetchEarnings: async () => {
          const { data } = await supabase
            .from('commissions')
            .select('*')
            .eq('agent_id', get().myNode?.id)
            .order('created_at', { ascending: false });
          
          set((state) => { state.commissions = data || []; });
        },

        withdraw: async (amount, method) => {
          const { error } = await supabase.rpc('process_withdrawal', {
            p_agent_id: get().myNode!.id,
            p_amount: amount,
            p_method: method,
          });
          if (error) throw error;
        },

        // ... más acciones
      }),
      {
        name: 'network-storage',
        storage: createJSONStorage(() => AsyncStorage),
      }
    )
  )
);
\`\`\`

## API Endpoints

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| POST | /network/join | Convertirse en agente |
| GET | /network/me | Mi nodo y estadísticas |
| GET | /network/earnings | Historial de comisiones |
| POST | /network/withdraw | Solicitar retiro |
| GET | /network/tree | Mi red (downline) |
| POST | /network/recruit | Invitar por email |
| GET | /network/leaderboard | Top earners |

## Flujos

### Conversión de Referido
1. Consumer usa código \`REF123\` al registrarse
2. DB: \`users.referrer_id\` = agente de \`REF123\`
3. Evento: \`ReferralRegisteredEvent\`
4. Primera compra del referido → \`ReferralConvertedEvent\`
5. Saga: Calcular comisión (15% primera compra)
6. DB: Insert \`commission\` con \`available_at = now() + 7 days\`
7. Notificación push al agente: "¡Ganaste $15! Disponible en 7 días"

### Escalamiento de Red
1. Agent recluta a 3 personas directamente
2. DB: \`agent_nodes.direct_recruits = 3\`
3. Policy: Evaluar upgrade a \`tier='sprout'\`
4. Evento: \`TierUpgradedEvent\`
5. Notificación: "¡Felicidades! Ahora eres Sprout. Ganas 12% + 2% de tu red"

### Retiro de Comisiones
1. Agent solicita retiro de $100
2. RPC \`process_withdrawal\`: Validar balance ≥ $100
3. DB: Insert \`withdrawal\` status='pending'
4. Admin review (automático si < $500, manual si >)
5. Procesamiento a cuenta bancaria/wallet
6. DB: Update \`withdrawal\` status='paid', decrementar \`available_balance\`
7. Notificación: "Tu retiro de $100 fue procesado"
