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
