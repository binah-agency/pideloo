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
