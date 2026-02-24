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
