import { withTamagui } from '@tamagui/next-plugin'
import path from 'path'

const tamaguiPlugin = withTamagui({
  config: path.resolve('../../packages/ui/src/tamagui.config.ts'),
  components: ['tamagui', '@pideloo/ui'],
  appDir: true,
  disableExtraction: true,
})

/** @type {import('next').NextConfig} */
const nextConfig = {
  transpilePackages: ['@pideloo/ui', 'react-native-web'],
  // 1. TURBO ahora va aquí, fuera de experimental
  turbo: {
    resolveAlias: {
      'react-native': 'react-native-web',
      '@tamagui/native': 'react-native-web',
    },
  },
experimental: {
    scrollRestoration: true,
    // Agrega esto para permitir el acceso desde tu red local
    allowedDevOrigins: ['192.168.1.102:3000', 'localhost:3000'],
  },
}

export default tamaguiPlugin(nextConfig)