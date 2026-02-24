export type UserRole = 'consumer' | 'agent' | 'supply';

export type AgentTier = 'seed' | 'sprout' | 'growth' | 'harvest';

export type OrderStatus = 'pending' | 'confirmed' | 'preparing' | 'ready' | 'delivered' | 'cancelled';

export type EarningType = 'sale' | 'referral' | 'network' | 'bonus';

export interface GeoLocation {
  lat: number;
  lng: number;
  address: string;
}
