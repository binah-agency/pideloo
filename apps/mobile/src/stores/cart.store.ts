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
