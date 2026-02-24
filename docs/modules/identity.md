# Módulo: Identity

## Propósito
Gestión de identidad, autenticación y perfiles de usuario. Soporta 3 tipos de actores: Consumer, Agent, Supply.

## Arquitectura

\`\`\`
┌─────────────────────────────────────────┐
│           IDENTITY MODULE                │
├─────────────────────────────────────────┤
│  Application                            │
│  ├── Commands: Register, Login, Logout  │
│  ├── Queries: GetProfile, ListUsers     │
│  └── Events: UserRegistered, RoleChanged │
├─────────────────────────────────────────┤
│  Domain                                 │
│  ├── Entities: User, Profile            │
│  ├── Value Objects: Email, Phone, Role  │
│  └── Repositories: IUserRepository      │
├─────────────────────────────────────────┤
│  Infrastructure                         │
│  ├── Supabase Auth (JWT)                │
│  ├── Database: users table              │
│  └── Web: AuthController                │
└─────────────────────────────────────────┘
\`\`\`

## Schema de Base de Datos (Supabase)

\`\`\`sql
-- Tabla: users
create table users (
  id uuid primary key default gen_random_uuid(),
  email text unique not null,
  phone text,
  name text not null,
  role text check (role in ('consumer', 'agent', 'supply')) not null,
  avatar_url text,
  metadata jsonb default '{}',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Tabla: profiles (extensión por rol)
create table profiles (
  id uuid primary key references users(id) on delete cascade,
  -- Consumer
  preferences jsonb default '{}',
  -- Agent
  tier text default 'seed',
  referral_code text unique,
  earnings_total decimal(12,2) default 0,
  network_size int default 0,
  -- Supply
  business_name text,
  business_address text,
  inventory_count int default 0,
  -- Common
  geo_location point,
  availability jsonb default '{}',
  verified boolean default false
);

-- RLS Policies
alter table users enable row level security;

create policy "Users can read own data"
  on users for select
  using (auth.uid() = id);

create policy "Users can update own data"
  on users for update
  using (auth.uid() = id);
\`\`\`

## Zod Schemas

\`\`\`typescript
// src/schemas/user.schema.ts
export const UserRoleSchema = z.enum(['consumer', 'agent', 'supply']);

export const UserSchema = z.object({
  id: z.string().uuid(),
  email: z.string().email(),
  phone: z.string().optional(),
  name: z.string().min(2).max(100),
  role: UserRoleSchema,
  avatarUrl: z.string().url().optional(),
  createdAt: z.string().datetime(),
});

export const RegisterSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
  name: z.string().min(2),
  role: UserRoleSchema,
  phone: z.string().optional(),
});

export const LoginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(1),
});

export type User = z.infer<typeof UserSchema>;
export type RegisterInput = z.infer<typeof RegisterSchema>;
export type LoginInput = z.infer<typeof LoginSchema>;
\`\`\`

## API Endpoints

| Método | Endpoint | Descripción | Auth |
|--------|----------|-------------|------|
| POST | /auth/register | Registro nuevo usuario | No |
| POST | /auth/login | Login con email/pass | No |
| POST | /auth/logout | Cerrar sesión | Sí |
| GET | /auth/me | Perfil actual | Sí |
| PUT | /auth/profile | Actualizar perfil | Sí |
| POST | /auth/role | Cambiar rol (consumer→agent) | Sí |

## Flujos

### Registro de Consumer
1. App: Formulario con Zod validation
2. API: \`RegisterSchema.parse()\` → Crear user en Supabase Auth
3. DB: Trigger crea perfil en \`users\` + \`profiles\`
4. App: Auto-login, redirect a Home

### Registro de Agent
1. Consumer existe → Click "Become Agent"
2. App: Formulario adicional (disponibilidad, zona)
3. API: Update \`role='agent'\`, generar \`referral_code\`
4. App: Onboarding agente, mostrar dashboard

## Eventos de Dominio

\`\`\`typescript
// UserRegistered
interface UserRegisteredEvent {
  userId: string;
  email: string;
  role: UserRole;
  timestamp: string;
  referralSource?: string; // Quien lo refirió
}

// AgentActivated
interface AgentActivatedEvent {
  userId: string;
  referralCode: string;
  tier: 'seed';
  timestamp: string;
}
\`\`\`

## Integraciones

- **Supabase Auth**: JWT, refresh tokens, MFA opcional
- **Zustand Store**: \`useAuthStore\` persiste sesión en AsyncStorage
- **Zod**: Validación en API y cliente
