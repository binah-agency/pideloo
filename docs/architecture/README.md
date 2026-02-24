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
