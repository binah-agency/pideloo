import { TamaguiOptions } from '@tamagui/static'

const options: TamaguiOptions = {
  // 1. Ruta a tu archivo de configuración principal
  config: './src/tamagui.config.ts',
  
  // 2. Qué componentes debe procesar (los tuyos y los de tamagui)
  components: ['tamagui', '@pideloo/ui'],
  
  // 3. Dónde exportar el CSS generado (útil para producción)
  outputCSS: './dist/tamagui.css',
  
  // 4. Optimización de plataformas
  platform: 'web',
  
  // 5. Nivel de log para depuración
  logTimings: true,
}

export default options