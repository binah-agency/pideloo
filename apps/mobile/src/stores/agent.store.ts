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
