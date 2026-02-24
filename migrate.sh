#!/bin/zsh  

# Pideloo Monorepo Migration Script
# Transforma estructura actual en monorepo con docs, Zustand, Zod, Supabase

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
DIM='\033[2m'
RESET='\033[0m'
BOLD='\033[1m'

ROOT_DIR=$(pwd)
BACKEND_DIR="$ROOT_DIR/backend/pideloo-backend"
FRONTEND_DIR="$ROOT_DIR/frontend"

log_info() { echo -e "${BLUE}ℹ${RESET} $1"; }
log_success() { echo -e "${GREEN}✓${RESET} $1"; }
log_warning() { echo -e "${YELLOW}⚠${RESET} $1"; }
log_section() { echo -e "\n${BOLD}${MAGENTA}=== $1 ===${RESET}\n"; }

# ============================================
# FASE 1: REVISAR ESTRUCTURA ACTUAL
# ============================================

review_current() {
    log_section "🔍 REVISANDO ESTRUCTURA ACTUAL"
    
    log_info "Backend encontrado en: $BACKEND_DIR"
    log_info "Frontend encontrado en: $FRONTEND_DIR"
    
    # Verificar proyectos existentes (Usando 'if' en lugar de '&&' para evitar que set -e aborte)
    if [ -d "$BACKEND_DIR" ]; then log_success "Backend NestJS detectado"; fi
    if [ -d "$FRONTEND_DIR/pideloo-mobile" ]; then log_success "Mobile Expo detectado"; fi
    if [ -d "$FRONTEND_DIR/pideloo-front" ]; then log_success "Web Next.js detectado"; fi
    if [ -d "$FRONTEND_DIR/pideloo-landing" ]; then log_success "Landing detectado"; fi
    if [ -d "$FRONTEND_DIR/pideloo-app" ]; then log_success "Vite app detectado"; fi
    if [ -d "$FRONTEND_DIR/pideloo-mobile-test" ]; then log_success "Mobile test detectado"; fi
    
    log_info "Procediendo con la migración automáticamente (sin validación)..."
}

# ============================================
# FASE 2: CREAR NUEVA ESTRUCTURA MONOREPO
# ============================================

create_monorepo_structure() {
    log_section "🏗️ CREANDO ESTRUCTURA MONOREPO"
    
    # Crear directorios nuevos
    mkdir -p "$ROOT_DIR/apps/api"
    mkdir -p "$ROOT_DIR/apps/mobile"
    mkdir -p "$ROOT_DIR/apps/web"
    mkdir -p "$ROOT_DIR/apps/landing"
    mkdir -p "$ROOT_DIR/packages/ui/src"
    mkdir -p "$ROOT_DIR/packages/types/src"
    mkdir -p "$ROOT_DIR/packages/config/typescript"
    mkdir -p "$ROOT_DIR/docs/modules"
    mkdir -p "$ROOT_DIR/docs/flows"
    mkdir -p "$ROOT_DIR/docs/architecture"
    mkdir -p "$ROOT_DIR/docs/api"
    mkdir -p "$ROOT_DIR/supabase"
    mkdir -p "$ROOT_DIR/scripts"
    
    log_info "Directorios creados"
    
    # Crear pnpm-workspace.yaml
    cat > "$ROOT_DIR/pnpm-workspace.yaml" << 'WORKSPACEEOF'
packages:
  - 'apps/*'
  - 'packages/*'
WORKSPACEEOF
    log_success "Creado pnpm-workspace.yaml"

    # Crear package.json root
    cat > "$ROOT_DIR/package.json" << 'PACKAGEEOF'
{
  "name": "pideloo-monorepo",
  "private": true,
  "version": "1.0.0",
  "description": "Pideloo - D2C Commerce Platform with Income Generation",
  "scripts": {
    "build": "turbo run build",
    "dev": "turbo run dev --parallel",
    "lint": "turbo run lint",
    "typecheck": "turbo run typecheck",
    "test": "turbo run test",
    "clean": "turbo run clean && rm -rf node_modules",
    "db:types": "supabase gen types typescript --project-id $SUPABASE_PROJECT_ID > packages/types/src/database.types.ts",
    "mobile": "pnpm --filter=@pideloo/mobile dev",
    "api": "pnpm --filter=@pideloo/api dev",
    "web": "pnpm --filter=@pideloo/web dev"
  },
  "devDependencies": {
    "turbo": "^1.11.0",
    "typescript": "^5.3.0"
  },
  "packageManager": "pnpm@8.12.0",
  "engines": {
    "node": ">=20.0.0"
  }
}
PACKAGEEOF
    log_success "Creado package.json root"

    # Crear turbo.json
    cat > "$ROOT_DIR/turbo.json" << 'TURBOEOF'
{
  "$schema": "https://turbo.build/schema.json",
  "globalDependencies": ["**/.env.*local"],
  "pipeline": {
    "build": {
      "dependsOn": ["^build"],
      "outputs": [".next/**", "!.next/cache/**", "dist/**", "web-build/**"]
    },
    "dev": {
      "cache": false,
      "persistent": true
    },
    "typecheck": {
      "dependsOn": ["^typecheck"]
    },
    "test": {
      "dependsOn": ["^build"]
    },
    "clean": {
      "cache": false
    }
  }
}
TURBOEOF
    log_success "Creado turbo.json"
}


# ============================================
# FASE 3: MIGRAR BACKEND
# ============================================

migrate_backend() {
    log_section "🔧 MIGRANDO BACKEND → apps/api"
    
    if [ -d "$BACKEND_DIR" ]; then
        # Usamos tar para ignorar node_modules y .git
        (cd "$BACKEND_DIR" && tar -cf - --exclude=node_modules --exclude=.git --exclude=dist .) | (cd "$ROOT_DIR/apps/api" && tar -xf -)
        log_success "Backend migrado a apps/api (ignorado node_modules y .git)"
        
        cat > "$ROOT_DIR/apps/api/package.json" << 'APIPACKAGEEOF'
{
  "name": "@pideloo/api",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "build": "nest build",
    "dev": "nest start --watch",
    "start": "nest start",
    "start:prod": "node dist/main",
    "lint": "eslint \"{src,apps,libs,test}/**/*.ts\" --fix",
    "test": "jest",
    "test:e2e": "jest --config ./test/jest-e2e.json",
    "typecheck": "tsc --noEmit",
    "clean": "rm -rf dist"
  },
  "dependencies": {
    "@nestjs/common": "^10.3.0",
    "@nestjs/core": "^10.3.0",
    "@nestjs/platform-express": "^10.3.0",
    "@nestjs/config": "^3.1.0",
    "@supabase/supabase-js": "^2.39.0",
    "zod": "^3.22.0",
    "zod-validation-error": "^3.0.0",
    "passport": "^0.7.0",
    "passport-jwt": "^4.0.0",
    "@nestjs/passport": "^10.0.0",
    "@nestjs/jwt": "^10.2.0",
    "class-validator": "^0.14.0",
    "class-transformer": "^0.5.0",
    "bcrypt": "^5.1.0",
    "reflect-metadata": "^0.1.0",
    "rxjs": "^7.8.0"
  },
  "devDependencies": {
    "@nestjs/cli": "^10.3.0",
    "@nestjs/schematics": "^10.1.0",
    "@nestjs/testing": "^10.3.0",
    "@types/node": "^20.10.0",
    "@types/bcrypt": "^5.0.0",
    "@types/passport-jwt": "^4.0.0",
    "typescript": "^5.3.0",
    "jest": "^29.7.0",
    "ts-jest": "^29.1.0"
  }
}
APIPACKAGEEOF
        log_success "Actualizado package.json con Supabase + Zod"
    fi
    
    # Crear estructura hexagonal
    mkdir -p "$ROOT_DIR/apps/api/src/modules/identity/application/commands"
    mkdir -p "$ROOT_DIR/apps/api/src/modules/identity/domain/entities"
    mkdir -p "$ROOT_DIR/apps/api/src/modules/identity/infrastructure/persistence/supabase"
    mkdir -p "$ROOT_DIR/apps/api/src/modules/catalog/application/queries"
    mkdir -p "$ROOT_DIR/apps/api/src/modules/ordering/domain/aggregates"
    mkdir -p "$ROOT_DIR/apps/api/src/modules/network/domain/entities"
    mkdir -p "$ROOT_DIR/apps/api/src/shared/schemas"
    mkdir -p "$ROOT_DIR/apps/api/src/shared/filters"
    
    cat > "$ROOT_DIR/apps/api/src/shared/schemas/base.schema.ts" << 'SCHEMAEOF'
import { z } from 'zod';

export const UuidSchema = z.string().uuid();
export const EmailSchema = z.string().email();
export const PhoneSchema = z.string().regex(/^\+?[1-9]\d{1,14}$/);
export const MoneySchema = z.number().positive().multipleOf(0.01);

export const TimestampSchema = z.union([
  z.string().datetime(),
  z.date(),
  z.number()
]);

export const PaginationSchema = z.object({
  page: z.number().int().positive().default(1),
  limit: z.number().int().positive().max(100).default(20),
});

export type Pagination = z.infer<typeof PaginationSchema>;
SCHEMAEOF

    cat > "$ROOT_DIR/apps/api/src/shared/filters/zod-exception.filter.ts" << 'FILTEREOF'
import { ExceptionFilter, Catch, ArgumentsHost, HttpStatus } from '@nestjs/common';
import { Response } from 'express';
import { ZodError, ZodIssue } from 'zod';
import { fromZodError } from 'zod-validation-error';

@Catch(ZodError)
export class ZodExceptionFilter implements ExceptionFilter {
  catch(exception: ZodError, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    
    const validationError = fromZodError(exception, {
      prefix: 'Validation failed',
      includePath: true,
    });

    response.status(HttpStatus.BAD_REQUEST).json({
      statusCode: HttpStatus.BAD_REQUEST,
      message: validationError.message,
      errors: exception.errors.map((err: ZodIssue) => ({
        path: err.path.join('.'),
        message: err.message,
      })),
      timestamp: new Date().toISOString(),
    });
  }
}
FILTEREOF
}

# ============================================
# FASE 4: MIGRAR MOBILE (pideloo-mobile → apps/mobile)
# ============================================

migrate_mobile() {
    log_section "📱 MIGRANDO MOBILE → apps/mobile"
    
    local MOBILE_SRC="$FRONTEND_DIR/pideloo-mobile"
    
    if [ -d "$MOBILE_SRC" ]; then
        # Usamos tar para ignorar node_modules y .git
        (cd "$MOBILE_SRC" && tar -cf - --exclude=node_modules --exclude=.git --exclude=.expo .) | (cd "$ROOT_DIR/apps/mobile" && tar -xf -)
        log_success "Mobile migrado a apps/mobile (ignorado node_modules y .git)"
        
        # Actualizar package.json
        cat > "$ROOT_DIR/apps/mobile/package.json" << 'EOF'
{
  "name": "@pideloo/mobile",
  "version": "1.0.0",
  "main": "index.ts",
  "scripts": {
    "dev": "expo start",
    "android": "expo start --android",
    "ios": "expo start --ios",
    "web": "expo start --web",
    "build": "expo export",
    "typecheck": "tsc --noEmit",
    "clean": "rm -rf node_modules .expo"
  },
  "dependencies": {
    "expo": "~50.0.0",
    "expo-router": "~3.4.0",
    "expo-status-bar": "~1.11.0",
    "react": "18.2.0",
    "react-native": "0.73.0",
    "@tamagui/core": "^1.88.0",
    "tamagui": "^1.88.0",
    "zustand": "^4.5.0",
    "zod": "^3.22.0",
    "@supabase/supabase-js": "^2.39.0",
    "@react-native-async-storage/async-storage": "1.21.0",
    "immer": "^10.0.0",
    "@tanstack/react-query": "^5.17.0",
    "axios": "^1.6.0"
  },
  "devDependencies": {
    "@babel/core": "^7.23.0",
    "@types/react": "~18.2.0",
    "typescript": "^5.3.0"
  }
}
EOF
        log_success "Actualizado package.json con Zustand + Zod + Supabase"
        
        # Crear estructura de stores Zustand
        mkdir -p "$ROOT_DIR/apps/mobile/src/stores"
        mkdir -p "$ROOT_DIR/apps/mobile/src/schemas"
        mkdir -p "$ROOT_DIR/apps/mobile/src/hooks"
        mkdir -p "$ROOT_DIR/apps/mobile/src/lib"
        
        # Store de autenticación
        cat > "$ROOT_DIR/apps/mobile/src/stores/auth.store.ts" << 'EOF'
import { create } from 'zustand';
import { persist, createJSONStorage } from 'zustand/middleware';
import { immer } from 'zustand/middleware/immer';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { z } from 'zod';

export const UserSchema = z.object({
  id: z.string().uuid(),
  email: z.string().email(),
  name: z.string().min(2),
  role: z.enum(['consumer', 'agent', 'supply']),
  tier: z.enum(['seed', 'sprout', 'growth', 'harvest']).optional(),
});

export type User = z.infer<typeof UserSchema>;

interface AuthState {
  user: User | null;
  token: string | null;
  isAuthenticated: boolean;
  isLoading: boolean;
}

interface AuthActions {
  login: (email: string, password: string) => Promise<void>;
  logout: () => void;
  setUser: (user: User) => void;
  updateProfile: (data: Partial<User>) => void;
}

export const useAuthStore = create<AuthState & AuthActions>()(
  immer(
    persist(
      (set, get) => ({
        user: null,
        token: null,
        isAuthenticated: false,
        isLoading: false,

        login: async (email, password) => {
          set((state) => { state.isLoading = true; });
          // TODO: Implementar llamada a API
          set((state) => { state.isLoading = false; });
        },

        logout: () => {
          set((state) => {
            state.user = null;
            state.token = null;
            state.isAuthenticated = false;
          });
        },

        setUser: (user) => {
          set((state) => {
            state.user = user;
            state.isAuthenticated = true;
          });
        },

        updateProfile: (data) => {
          set((state) => {
            if (state.user) {
              state.user = { ...state.user, ...data };
            }
          });
        },
      }),
      {
        name: 'auth-storage',
        storage: createJSONStorage(() => AsyncStorage),
        partialize: (state) => ({ 
          user: state.user, 
          token: state.token, 
          isAuthenticated: state.isAuthenticated 
        }),
      }
    )
  )
);
EOF

        # Store de carrito
        cat > "$ROOT_DIR/apps/mobile/src/stores/cart.store.ts" << 'EOF'
import { create } from 'zustand';
import { persist, createJSONStorage } from 'zustand/middleware';
import { immer } from 'zustand/middleware/immer';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { z } from 'zod';

export const CartItemSchema = z.object({
  productId: z.string(),
  name: z.string(),
  price: z.number().positive(),
  quantity: z.number().int().positive(),
  image: z.string().url().optional(),
});

export type CartItem = z.infer<typeof CartItemSchema>;

interface CartState {
  items: CartItem[];
  total: number;
}

interface CartActions {
  addItem: (item: CartItem) => void;
  removeItem: (productId: string) => void;
  updateQuantity: (productId: string, quantity: number) => void;
  clearCart: () => void;
  getTotalItems: () => number;
  getTotalPrice: () => number;
}

export const useCartStore = create<CartState & CartActions>()(
  immer(
    persist(
      (set, get) => ({
        items: [],
        total: 0,

        addItem: (item) => {
          set((state) => {
            const existing = state.items.find((i) => i.productId === item.productId);
            if (existing) {
              existing.quantity += item.quantity;
            } else {
              state.items.push(item);
            }
            state.total = state.items.reduce((sum, i) => sum + i.price * i.quantity, 0);
          });
        },

        removeItem: (productId) => {
          set((state) => {
            state.items = state.items.filter((i) => i.productId !== productId);
            state.total = state.items.reduce((sum, i) => sum + i.price * i.quantity, 0);
          });
        },

        updateQuantity: (productId, quantity) => {
          set((state) => {
            const item = state.items.find((i) => i.productId === productId);
            if (item) {
              item.quantity = quantity;
              if (quantity <= 0) {
                state.items = state.items.filter((i) => i.productId !== productId);
              }
            }
            state.total = state.items.reduce((sum, i) => sum + i.price * i.quantity, 0);
          });
        },

        clearCart: () => set({ items: [], total: 0 }),

        getTotalItems: () => {
          return get().items.reduce((sum, item) => sum + item.quantity, 0);
        },

        getTotalPrice: () => get().total,
      }),
      {
        name: 'cart-storage',
        storage: createJSONStorage(() => AsyncStorage),
      }
    )
  )
);
EOF

        # Store de agente (ingresos)
        cat > "$ROOT_DIR/apps/mobile/src/stores/agent.store.ts" << 'EOF'
import { create } from 'zustand';
import { persist, createJSONStorage } from 'zustand/middleware';
import { immer } from 'zustand/middleware/immer';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { z } from 'zod';

export const EarningSchema = z.object({
  id: z.string(),
  amount: z.number().positive(),
  type: z.enum(['sale', 'referral', 'network', 'bonus']),
  description: z.string(),
  createdAt: z.string().datetime(),
  status: z.enum(['pending', 'available', 'withdrawn']),
});

export type Earning = z.infer<typeof EarningSchema>;

interface AgentState {
  earnings: Earning[];
  balance: number;
  networkSize: number;
  tier: 'seed' | 'sprout' | 'growth' | 'harvest';
  referralCode: string | null;
}

interface AgentActions {
  addEarning: (earning: Earning) => void;
  withdraw: (amount: number) => Promise<void>;
  generateReferralCode: () => void;
  recruitAgent: (agentId: string) => void;
}

export const useAgentStore = create<AgentState & AgentActions>()(
  immer(
    persist(
      (set, get) => ({
        earnings: [],
        balance: 0,
        networkSize: 0,
        tier: 'seed',
        referralCode: null,

        addEarning: (earning) => {
          set((state) => {
            state.earnings.unshift(earning);
            if (earning.status === 'available') {
              state.balance += earning.amount;
            }
          });
        },

        withdraw: async (amount) => {
          if (get().balance < amount) throw new Error('Insufficient balance');
          // TODO: Implementar retiro
          set((state) => { state.balance -= amount; });
        },

        generateReferralCode: () => {
          const code = Math.random().toString(36).substring(2, 8).toUpperCase();
          set((state) => { state.referralCode = code; });
        },

        recruitAgent: (agentId) => {
          set((state) => { state.networkSize += 1; });
        },
      }),
      {
        name: 'agent-storage',
        storage: createJSONStorage(() => AsyncStorage),
      }
    )
  )
);
EOF

        # Cliente Supabase
        cat > "$ROOT_DIR/apps/mobile/src/lib/supabase.ts" << 'EOF'
import { createClient } from '@supabase/supabase-js';
import AsyncStorage from '@react-native-async-storage/async-storage';

const supabaseUrl = process.env.EXPO_PUBLIC_SUPABASE_URL!;
const supabaseAnonKey = process.env.EXPO_PUBLIC_SUPABASE_ANON_KEY!;

export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    storage: AsyncStorage,
    autoRefreshToken: true,
    persistSession: true,
    detectSessionInUrl: false,
  },
});
EOF

        # Hook de Zod para formularios
        cat > "$ROOT_DIR/apps/mobile/src/hooks/useZodForm.ts" << 'EOF'
import { useState, useCallback } from 'react';
import { z, ZodSchema } from 'zod';

interface UseZodFormOptions<T extends ZodSchema> {
  schema: T;
  onSubmit: (data: z.infer<T>) => Promise<void>;
}

export function useZodForm<T extends ZodSchema>({ schema, onSubmit }: UseZodFormOptions<T>) {
  const [data, setData] = useState<Partial<z.infer<T>>>({});
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [isSubmitting, setIsSubmitting] = useState(false);

  const setValue = useCallback((key: keyof z.infer<T>, value: any) => {
    setData((prev) => ({ ...prev, [key]: value }));
    // Clear error when field is modified
    if (errors[key as string]) {
      setErrors((prev) => {
        const newErrors = { ...prev };
        delete newErrors[key as string];
        return newErrors;
      });
    }
  }, [errors]);

  const handleSubmit = useCallback(async () => {
    setIsSubmitting(true);
    setErrors({});

    try {
      const validated = schema.parse(data);
      await onSubmit(validated);
      return true;
    } catch (error) {
      if (error instanceof z.ZodError) {
        const formattedErrors: Record<string, string> = {};
        error.errors.forEach((err) => {
          formattedErrors[err.path.join('.')] = err.message;
        });
        setErrors(formattedErrors);
      }
      return false;
    } finally {
      setIsSubmitting(false);
    }
  }, [data, schema, onSubmit]);

  return {
    data,
    errors,
    isSubmitting,
    setValue,
    handleSubmit,
  };
}
EOF
    fi
}

# ============================================
# FASE 5: MIGRAR WEB (pideloo-front → apps/web)
# ============================================

migrate_web() {
    log_section "🌐 MIGRANDO WEB → apps/web"
    
    local WEB_SRC="$FRONTEND_DIR/pideloo-front"
    
    if [ -d "$WEB_SRC" ]; then
        (cd "$WEB_SRC" && tar -cf - --exclude=node_modules --exclude=.git --exclude=.next .) | (cd "$ROOT_DIR/apps/web" && tar -xf -)
        log_success "Web migrado a apps/web (ignorado node_modules y .git)"
        
        # Ensure the directory exists before writing to it
        mkdir -p "$ROOT_DIR/apps/web/src/lib"
        
        # Actualizar para Supabase SSR
        cat > "$ROOT_DIR/apps/web/src/lib/supabase.ts" << 'EOF'
import { createClient } from '@supabase/supabase-js';
import { createClientComponentClient } from '@supabase/auth-helpers-nextjs';

// Cliente para Server Components
export const createServerClient = () => {
  return createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
  );
};

// Cliente para Client Components
export const createBrowserClient = () => {
  return createClientComponentClient();
};
EOF
    fi
}

# ============================================
# FASE 6: MIGRAR LANDING
# ============================================

migrate_landing() {
    log_section "🎯 MIGRANDO LANDING → apps/landing"
    
    local LANDING_SRC="$FRONTEND_DIR/pideloo-landing"
    
    if [ -d "$LANDING_SRC" ]; then
        (cd "$LANDING_SRC" && tar -cf - --exclude=node_modules --exclude=.git --exclude=.next .) | (cd "$ROOT_DIR/apps/landing" && tar -xf -)
        log_success "Landing migrado a apps/landing (ignorado node_modules y .git)"
    fi
}

# ============================================
# FASE 7: CREAR PACKAGES COMPARTIDOS
# ============================================

create_packages() {
    log_section "📦 CREANDO PACKAGES COMPARTIDOS"
    
    # Package types
    cat > "$ROOT_DIR/packages/types/package.json" << 'EOF'
{
  "name": "@pideloo/types",
  "version": "1.0.0",
  "main": "./src/index.ts",
  "types": "./src/index.ts",
  "scripts": {
    "typecheck": "tsc --noEmit"
  },
  "devDependencies": {
    "typescript": "^5.3.0"
  }
}
EOF

    cat > "$ROOT_DIR/packages/types/src/index.ts" << 'EOF'
// Exportar tipos de base de datos (generados por Supabase)
export * from './database.types';

// Tipos de dominio
export * from './domain.types';

// Tipos de API
export * from './api.types';
EOF

    cat > "$ROOT_DIR/packages/types/src/domain.types.ts" << 'EOF'
export type UserRole = 'consumer' | 'agent' | 'supply';

export type AgentTier = 'seed' | 'sprout' | 'growth' | 'harvest';

export type OrderStatus = 'pending' | 'confirmed' | 'preparing' | 'ready' | 'delivered' | 'cancelled';

export type EarningType = 'sale' | 'referral' | 'network' | 'bonus';

export interface GeoLocation {
  lat: number;
  lng: number;
  address: string;
}
EOF

    cat > "$ROOT_DIR/packages/types/src/api.types.ts" << 'EOF'
export interface ApiResponse<T> {
  data: T;
  success: boolean;
  message?: string;
}

export interface PaginatedResponse<T> {
  data: T[];
  total: number;
  page: number;
  limit: number;
  hasMore: boolean;
}
EOF

    # Placeholder para database.types.ts (se genera con pnpm db:types)
    cat > "$ROOT_DIR/packages/types/src/database.types.ts" << 'EOF'
// Este archivo se genera automáticamente con:
// pnpm db:types
// 
// Mientras tanto, usar tipos básicos:

export interface Database {
  public: {
    Tables: {
      users: {
        Row: {
          id: string;
          email: string;
          name: string;
          role: 'consumer' | 'agent' | 'supply';
          created_at: string;
        };
      };
      orders: {
        Row: {
          id: string;
          user_id: string;
          total: number;
          status: string;
          created_at: string;
        };
      };
    };
  };
}
EOF

    # Package UI
    cat > "$ROOT_DIR/packages/ui/package.json" << 'EOF'
{
  "name": "@pideloo/ui",
  "version": "1.0.0",
  "main": "./src/index.ts",
  "scripts": {
    "typecheck": "tsc --noEmit"
  },
  "dependencies": {
    "@tamagui/core": "^1.88.0",
    "tamagui": "^1.88.0"
  },
  "devDependencies": {
    "typescript": "^5.3.0"
  }
}
EOF

    cat > "$ROOT_DIR/packages/ui/src/index.ts" << 'EOF'
export * from '@tamagui/core';
export * from './theme';
EOF

    # Package config
    cat > "$ROOT_DIR/packages/config/package.json" << 'EOF'
{
  "name": "@pideloo/config",
  "version": "1.0.0",
  "private": true
}
EOF

    cat > "$ROOT_DIR/packages/config/typescript/base.json" << 'TSCONFIGEOF'
{
  "compilerOptions": {
    "target": "ES2020",
    "lib": ["ES2020"],
    "jsx": "react-jsx",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "allowJs": true,
    "checkJs": false,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true,
    "strict": true,
    "noImplicitAny": true,
    "strictNullChecks": true,
    "noImplicitThis": true,
    "alwaysStrict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "esModuleInterop": true,
    "forceConsistentCasingInFileNames": true,
    "skipLibCheck": true
  },
  "exclude": ["node_modules", "dist", "build"]
}
TSCONFIGEOF

}

# ============================================
# EJECUCIÓN PRINCIPAL
# ============================================

main() {
    review_current
    create_monorepo_structure
    migrate_backend
    migrate_mobile
    migrate_web
    migrate_landing
    create_packages
    
    log_section "✅ MIGRACIÓN COMPLETADA"
    log_info "Siguientes pasos:"
    echo -e "1. Ejecuta ${BOLD}pnpm install${RESET} para instalar dependencias."
    echo -e "2. Configura ${BOLD}.env${RESET} en apps/api y apps/web."
    echo -e "3. Inicia el entorno de desarrollo con ${BOLD}pnpm dev${RESET}."
    echo -e "4. Genera tipos de base de datos con ${BOLD}pnpm db:types${RESET}."
}

# Lanzar script
main