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
