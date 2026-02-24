#!/bin/bash

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
# FASE 8: CREAR DOCUMENTACIÓN COMPLETA
# ============================================

create_documentation() {
    log_section "📚 CREANDO DOCUMENTACIÓN COMPLETA"
    
    # README de docs
    cat > "$ROOT_DIR/docs/README.md" << 'DOCSREADMEEOF'
# Pideloo Documentation

## Estructura

- [\`modules/\`](./modules/) - Documentación por módulo de negocio
- [\`flows/\`](./flows/) - Diagramas y flujos de proceso
- [\`architecture/\`](./architecture/) - Decisiones arquitectónicas
- [\`api/\`](./api/) - API documentation

## Módulos Principales

| Módulo | Descripción | Tech Stack |
|--------|-------------|------------|
| [Identity](./modules/identity.md) | Autenticación y perfiles | Supabase Auth + Zod |
| [Catalog](./modules/catalog.md) | Catálogo virtual unificado | Supabase + Zod |
| [Ordering](./modules/ordering.md) | Órdenes y fulfillment | Supabase + Zustand |
| [Network](./modules/network.md) | Red de ingresos y referidos | Supabase + Zustand |

## Flujos Clave

- [Onboarding](./flows/onboarding.md) - Primeros pasos de usuario
- [Purchase](./flows/purchase.md) - Flujo de compra D2C
- [Income Generation](./flows/income-generation.md) - Generación de ingresos
- [Referral](./flows/referral.md) - Sistema de referidos
- [Supply Aggregation](./flows/supply-aggregation.md) - Agregación de oferta
DOCSREADMEEOF


    # Documento: Identity Module
    cat > "$ROOT_DIR/docs/modules/identity.md" << 'IDENTITYEOF'
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
IDENTITYEOF

    # Documento: Catalog Module
    cat > "$ROOT_DIR/docs/modules/catalog.md" << 'CATALOGEOF'
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
CATALOGEOF

    # Documento: Ordering Module
    cat > "$ROOT_DIR/docs/modules/ordering.md" << 'ORDERINGEOF'
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
ORDERINGEOF

    # Documento: Network Module
    cat > "$ROOT_DIR/docs/modules/network.md" << 'NETWORKEOF'
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
NETWORKEOF

    # Crear flujos de proceso
    cat > "$ROOT_DIR/docs/flows/README.md" << 'FLOWSREADMEEOF'
# Flujos de Proceso

## Índice de Flujos

- [Onboarding](./onboarding.md) - Primeros pasos de usuario
- [Purchase](./purchase.md) - Flujo completo de compra
- [Income Generation](./income-generation.md) - Cómo se generan ingresos
- [Referral](./referral.md) - Sistema de referidos
- [Supply Aggregation](./supply-aggregation.md) - Agregación de oferta
- [Fulfillment](./fulfillment.md) - Desde orden hasta entrega
FLOWSREADMEEOF

    cat > "$ROOT_DIR/docs/flows/onboarding.md" << 'ONBOARDINGEOF'
# Flujo: Onboarding

## Onboarding de Consumer

\`\`\`mermaid
graph TD
    A[Descarga App] --> B{Selecciona modo}
    B -->|Quiero Comprar| C[Registro Consumer]
    B -->|Quiero Ganar| D[Registro Agent]
    B -->|Tengo Inventario| E[Registro Supply]
    
    C --> F[Phone/Email]
    F --> G[Verificación]
    G --> H[Ubicación]
    H --> I[Home/Feed]
    
    D --> J[Datos básicos]
    J --> K[Disponibilidad]
    K --> L[Zona de trabajo]
    L --> M[Generar código]
    M --> N[Dashboard Agent]
    
    E --> O[Datos negocio]
    O --> P[Inventario inicial]
    P --> Q[Ubicación exacta]
    Q --> R[Dashboard Supply]
\`\`\`

## Onboarding de Agent (detalle)

| Paso | Acción | Tiempo | Objetivo |
|------|--------|--------|----------|
| 1 | Descargar app | 2 min | Acceso |
| 2 | "Become Agent" | 1 min | Intención |
| 3 | Formulario (3 campos) | 3 min | Datos mínimos |
| 4 | Video de 2 min | 2 min | Expectativas |
| 5 | Generar código | 30 seg | Primer "win" |
| 6 | Compartir tutorial | 5 min | Primera acción |
| 7 | Primera comisión | Variable | Hook emocional |

**Meta: Primera comisión en < 48 horas**
ONBOARDINGEOF

    cat > "$ROOT_DIR/docs/flows/purchase.md" << 'PURCHASEEOF'
# Flujo: Purchase (Compra D2C)

## Flujo Completo

\`\`\`
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  DISCOVERY  │────►│   CART      │────►│  CHECKOUT   │
│             │     │             │     │             │
│ • Feed      │     │ • Add items │     │ • Address   │
│ • Search    │     │ • Quantity  │     │ • Time slot │
│ • Category  │     │ • Remove    │     │ • Payment   │
└─────────────┘     └─────────────┘     └──────┬──────┘
                                                  │
┌─────────────┐     ┌─────────────┐     ┌─────────┴─────────┐
│   REVIEW    │◄────│  DELIVERY   │◄────│   PROCESSING      │
│             │     │             │     │                   │
│ • Rating    │     │ • Tracking  │     │ • Allocate stock  │
│ • Tip       │     │ • Notify    │     │ • Confirm   │     │ • Calculate $   │
│ • Reorder   │     │             │     │ • Notify all      │
└─────────────┘     └─────────────┘     └─────────────────┘
\`\`\`

## Estados de Orden

| Estado | Descripción | Actor | Tiempo típico |
|--------|-------------|-------|---------------|
| \`cart\` | Carrito activo | Consumer | Variable |
| \`pending\` | Orden creada, esperando pago | System | < 5 min |
| \`confirmed\` | Pago recibido | System | Instant |
| \`preparing\` | Supply node preparando | Supply | 10-30 min |
| \`ready\` | Listo para pickup | Supply | - |
| \`in_transit\` | En camino | Delivery | 15-45 min |
| \`delivered\` | Entregado | Delivery | - |
| \`cancelled\` | Cancelado | Consumer/Supply | - |

## Puntos de Decisión

1. **Stock disponible?** - Sí: Continuar
   - No: Sugerir alternativa o pre-order

2. **Agente referido?**
   - Sí: Aplicar descuento 10%, calcular comisión
   - No: Precio normal

3. **Múltiple supply nodes?**
   - Optimizar: Menos splits = mejor experiencia
   - Fallback: Segundo node si primero falla
PURCHASEEOF

    cat > "$ROOT_DIR/docs/flows/income-generation.md" << 'INCOMEOF'
# Flujo: Income Generation

## Modelos de Ingreso

### 1. Direct Sales (Venta Directa)

\`\`\`
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Agent     │────►│   Share     │────►│   Sale      │
│             │     │             │     │             │
│ • Elige     │     │ • WhatsApp  │     │ • Consumer  │
│   productos │     │ • Instagram │     │   compra    │
│ • Crea      │     │ • TikTok    │     │ • Paga      │
│   mensaje   │     │ • QR físico │     │   $100      │
└─────────────┘     └─────────────┘     └──────┬──────┘
                                               │
                                        ┌──────┴──────┐
                                        │  COMMISSION   │
                                        │               │
                                        │ Agent: $15    │
                                        │ (15%)         │
                                        └───────────────┘
\`\`\`

### 2. Network Building (Red de reclutas)

\`\`\`
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Agent A   │────►│  Recluta    │────►│  Agent B    │
│  (Harvest)  │     │  Agent B    │     │  (Sprout)   │
└─────────────┘     └─────────────┘     └──────┬──────┘
                                              │
                                       ┌──────┴──────┐
                                       │  VENTA B    │
                                       │  $100       │
                                       └──────┬──────┘
                                              │
                                       ┌──────┴──────┐
                                       │  COMMISSIONS  │
                                       │               │
                                       │ B: $12 (12%)  │
                                       │ A: $2 (2% L1) │
                                       └───────────────┘
\`\`\`

### 3. Supply Curation (Curador)

\`\`\`
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Scout     │────►│  Registra   │────►│  Tienda     │
│             │     │  Tienda     │     │  vende      │
│ • Mapea     │     │ • Fotos     │     │  $1000/mes  │
│   zona      │     │ • Datos     │     │             │
│ • Negocia   │     │ • Contrato  │     │             │
└─────────────┘     └─────────────┘     └──────┬──────┘
                                               │
                                        ┌──────┴──────┐
                                        │  COMMISSION   │
                                        │               │
                                        │ Scout: $50    │
                                        │ (registro)    │
                                        │ + $20/mes     │
                                        │ (1% ongoing)  │
                                        └───────────────┘
\`\`\`

## Escalamiento de Ingresos (Ejemplo)

| Mes | Modelo Principal | Volumen | Ingreso | Acumulado |
|-----|------------------|---------|---------|-----------|
| 1 | Direct Sales | $500 ventas | $75 | $75 |
| 2 | Direct Sales | $2,000 | $300 | $375 |
| 3 | Direct + 1 recluta | $2,000 + $1,000 red | $300 + $20 | $695 |
| 6 | Network (5 reclutas) | $5,000 propio + $10,000 red | $750 + $200 | $3,500+ |
| 12 | Harvest tier | $10,000 + $50,000 red | $2,000 + $1,000 | $15,000+ |
INCOMEOF

    # Documento de arquitectura
    cat > "$ROOT_DIR/docs/architecture/README.md" << 'ARCHITECTUREEOF'
# Arquitectura de Pideloo

## Principios

1. **Mobile-First**: Diseñado para smartphones de gama media
2. **Offline-Capable**: Funciona sin conexión, sync cuando hay
3. **Real-time**: Updates instantáneos vía Supabase Realtime
4. **Type-Safe**: Zod + TypeScript en todo el stack
5. **Hexagonal**: Domain logic independiente de infraestructura

## Stack Tecnológico

\`\`\`
┌─────────────────────────────────────────┐
│           PRESENTATION                  │
│  ┌─────────┐ ┌─────────┐ ┌───────────┐ │
│  │  Mobile │ │   Web   │ │  Landing  │ │
│  │ (Expo)  │ │(Next.js)│ │(Next.js)  │ │
│  └────┬────┘ └────┬────┘ └─────┬─────┘ │
│       └─────────────┴────────────┘      │
│              Zustand + Tamagui          │
├─────────────────────────────────────────┤
│           APPLICATION                   │
│         NestJS (Hexagonal)              │
│  ┌─────────┐ ┌─────────┐ ┌───────────┐ │
│  │ Identity│ │ Catalog │ │  Ordering │ │
│  │ Network │ └────┬────┘ │  (Sagas)  │ │
│  └────┬────┘      │      └─────┬─────┘ │
│       └───────────┴────────────┘        │
│              Zod Validation             │
├─────────────────────────────────────────┤
│           INFRASTRUCTURE                │
│  ┌─────────┐ ┌─────────┐ ┌───────────┐ │
│  │Supabase │ │  Redis  │ │  Queue    │ │
│  │(DB+Auth)│ │ (Cache) │ │ (Bull)    │ │
│  └─────────┘ └─────────┘ └───────────┘ │
│         Realtime Subscriptions          │
└─────────────────────────────────────────┘
\`\`\`

## Decisiones Clave

### ¿Por qué Zustand sobre Redux/Context?
- Menos boilerplate
- Mejor performance en mobile
- Persistencia simple
- TypeScript nativo

### ¿Por qué Supabase sobre自建 Backend?
- Auth incluido
- Realtime subscriptions
- PostgreSQL con RLS
- Menos devops

### ¿Por qué Zod sobre Joi/Yup?
- Type inference
- Composable schemas
- Native TypeScript
- Menos bundle size
ARCHITECTUREEOF

    log_success "Documentación completa creada en docs/"
}


# ============================================
# FASE 9: CREAR ARCHIVOS ROOT FINALES
# ============================================

create_final_root_files() {
    log_section "📄 CREANDO ARCHIVOS ROOT FINALES"
    
    # .gitignore actualizado
    cat > "$ROOT_DIR/.gitignore" << 'EOF'
# Dependencies
node_modules
.pnpm-store
.yarn
package-lock.json
yarn.lock

# Build outputs
dist
build
.next
web-build
*.tsbuildinfo
.turbo

# Environment
.env
.env.local
.env.*.local
!.env.example

# Supabase
.supabase
supabase/.temp
supabase/seed.sql

# IDE
.idea
.vscode
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db
desktop.ini

# Logs
*.log
npm-debug.log*
yarn-debug.log*
pnpm-debug.log*
lerna-debug.log*

# Testing
coverage
.nyc_output

# Misc
.cache
.temp
tmp
*.pid
*.seed
*.pid.lock

# Mobile
apps/mobile/.expo
apps/mobile/ios
apps/mobile/android
apps/mobile/*.ipa
apps/mobile/*.apk

# Keep these
!.gitkeep
EOF

    # Crear .env.example
    cat > "$ROOT_DIR/.env.example" << 'EOF'
# Supabase
SUPABASE_PROJECT_ID=your-project-id
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key

# API (apps/api)
DATABASE_URL=postgresql://postgres:[password]@db.your-project.supabase.co:5432/postgres
JWT_SECRET=your-jwt-secret
PORT=3001

# Mobile (apps/mobile)
EXPO_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
EXPO_PUBLIC_SUPABASE_ANON_KEY=your-anon-key

# Web (apps/web)
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
EOF

    # Script de utilidad
    cat > "$ROOT_DIR/scripts/setup.sh" << 'EOF'
#!/bin/bash

echo "🚀 Pideloo Setup Script"

# Check Node version
if ! node -v | grep -q "v20"; then
    echo "❌ Node 20+ requerido. Actual: $(node -v)"
    exit 1
fi

# Check pnpm
if ! command -v pnpm &> /dev/null; then
    echo "❌ pnpm no instalado. Instalando..."
    npm install -g pnpm
fi

echo "📦 Instalando dependencias..."
pnpm install

echo "🔧 Configurando Supabase..."
if [ ! -f .env ]; then
    cp .env.example .env
    echo "⚠️  Edita .env con tus credenciales de Supabase"
fi

echo "✅ Setup completo!"
echo ""
echo "Próximos pasos:"
echo "  1. Editar .env con credenciales"
echo "  2. pnpm dev (iniciar desarrollo)"
echo "  3. Abrir http://localhost:3001 (API) y Expo Go (Mobile)"
EOF

    chmod +x "$ROOT_DIR/scripts/setup.sh"
    
    # Makefile para comandos comunes
    cat > "$ROOT_DIR/Makefile" << 'EOF'
.PHONY: dev install clean typecheck db-types test

dev:
	@pnpm dev

install:
	@pnpm install

clean:
	@pnpm clean

typecheck:
	@pnpm typecheck

db-types:
	@pnpm db:types

test:
	@pnpm test

setup:
	@./scripts/setup.sh

mobile:
	@pnpm --filter=@pideloo/mobile dev

api:
	@pnpm --filter=@pideloo/api dev

web:
	@pnpm --filter=@pideloo/web dev
EOF

    log_success "Archivos de utilidad creados"
}


# ============================================
# FASE 10: RESUMEN Y LIMPIEZA
# ============================================

print_summary() {
    log_section "✅ MIGRACIÓN COMPLETADA"
    
    echo -e "${GREEN}Estructura final:${RESET}"
    if command -v tree &> /dev/null; then
        tree -L 2 "$ROOT_DIR" 2>/dev/null || find "$ROOT_DIR" -maxdepth 2 -type d | head -20
    else
        find "$ROOT_DIR" -maxdepth 2 -type d | sed 's|[^/]*/| |g' | head -20
    fi
    
    echo ""
    echo -e "${CYAN}Resumen de cambios:${RESET}"
    echo "  • Backend migrado: backend/pideloo-backend → apps/api"
    echo "  • Mobile migrado: frontend/pideloo-mobile → apps/mobile"
    echo "  • Web migrado: frontend/pideloo-front → apps/web"
    echo "  • Landing migrado: frontend/pideloo-landing → apps/landing"
    echo "  • Zustand stores creados en apps/mobile/src/stores/"
    echo "  • Zod schemas creados en apps/mobile/src/schemas/"
    echo "  • Documentación completa en docs/"
    echo "  • Packages compartidos creados"
    
    echo ""
    echo -e "${YELLOW}Próximos pasos:${RESET}"
    echo "  1. Revisar archivos migrados en apps/"
    echo "  2. Copiar .env.example a .env y configurar"
    echo "  3. pnpm install"
    echo "  4. pnpm dev"
    
    echo ""
    echo -e "${MAGENTA}📚 Documentación disponible:${RESET}"
    echo "  • docs/modules/identity.md"
    echo "  • docs/modules/catalog.md"
    echo "  • docs/modules/ordering.md"
    echo "  • docs/modules/network.md"
    echo "  • docs/flows/"
    echo "  • docs/architecture/"
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
    create_documentation
    create_final_root_files
    print_summary
}

main "$@"