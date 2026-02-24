import { withTamagui } from '@tamagui/next-plugin'
import path from 'path'

// Detectamos si estamos en producción para habilitar la extracción de CSS
const isProduction = process.env.NODE_ENV === 'production'

const tamaguiPlugin = withTamagui({
  config: path.resolve('../../packages/ui/src/tamagui.config.ts'),
  components: ['tamagui', '@pideloo/ui'],
  appDir: true,
  // 1. Optimización: Extraemos CSS solo en producción para mejor performance
  // En desarrollo lo desactivamos para que el Hot Module Replacement (HMR) sea instantáneo.
  disableExtraction: !isProduction,
  outputCSS: isProduction ? './public/tamagui.css' : null,
})

/** @type {import('next').NextConfig} */
const nextConfig = {
  // 2. Estándares de calidad
  reactStrictMode: true,
  swcMinify: true,

  transpilePackages: [
    '@pideloo/ui', 
    'react-native-web',
    'tamagui',
    '@tamagui/toast',
    '@tamagui/lucide-icons',
    '@tamagui/animations-react-native', // ¡Añadido para tus animaciones!
  ],

  turbo: {
    resolveAlias: {
      'react-native': 'react-native-web',
      '@tamagui/native': 'react-native-web',
    },
  },

  experimental: {
    scrollRestoration: true,
    allowedDevOrigins: ['192.168.1.102:3000', 'localhost:3000'],
    
    // 3. ¡Súper Optimización! Reduce el bundle al importar solo los iconos/componentes usados
    optimizePackageImports: [
      'tamagui',
      '@tamagui/lucide-icons',
      '@tamagui/toast',
      '@pideloo/ui'
    ],
  },

  // 4. Manejo de imágenes (útil para logos de restaurantes o avatares)
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: '**', // Permite imágenes de cualquier origen (ajustar en prod)
      },
    ],
  },
}

export default tamaguiPlugin(nextConfig)