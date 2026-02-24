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
