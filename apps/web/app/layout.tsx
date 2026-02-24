import { Metadata, Viewport } from 'next'
import { Provider } from '@pideloo/ui'
import TamaguiRegistry from './TamaguiRegistry'

// 1. SEO: Configuración de metadatos estáticos
export const metadata: Metadata = {
  metadataBase: new URL(process.env.NEXT_PUBLIC_SITE_URL || 'http://localhost:3000'),
  title: {
    default: 'Pideloo - Tu App de Delivery',
    template: '%s | Pideloo'
  },

  description: 'Pideloo es la forma más rápida y sencilla de pedir comida a domicilio.',
  keywords: ['delivery', 'comida', 'domicilio', 'pideloo', 'restaurantes'],
  authors: [{ name: 'Pideloo Team' }],
  robots: 'index, follow',
  openGraph: {
    type: 'website',
    locale: 'es_VE',
    url: 'https://pideloo.com',
    title: 'Pideloo - Tu App de Delivery',
    description: 'Pide en tus restaurantes favoritos con Pideloo.',
    siteName: 'Pideloo',
    images: [{ url: '/og-image.png', width: 1200, height: 630 }]
  },
  twitter: {
    card: 'summary_large_image',
    title: 'Pideloo',
    description: 'Tu comida favorita en un clic.',
    images: ['/twitter-image.png'],
  }
}

// 2. SEO/Performance: Configuración del Viewport (crítico para móviles)
export const viewport: Viewport = {
  width: 'device-width',
  initialScale: 1,
  themeColor: '#ffffff', // Cámbialo al color de tu marca
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    // suppressHydrationWarning es vital con Tamagui/Theme providers
    // para evitar errores de hidratación por el cambio de clases del tema.
    <html lang="es" suppressHydrationWarning>
      <head>
        {/* Favicons y Manifest para PWA (SEM/Rendimiento) */}
        <link rel="icon" href="/favicon.ico" />
        <link rel="manifest" href="/manifest.json" />
      </head>
      <body suppressHydrationWarning>
        <TamaguiRegistry>
          <Provider defaultTheme="light">
            {/* 3. SEM/Accesibilidad: Estructura semántica básica */}
            <main role="main">
              {children}
            </main>
          </Provider>
        </TamaguiRegistry>
      </body>
    </html>
  )
}