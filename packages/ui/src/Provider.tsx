'use client'

import { useColorScheme } from 'react-native'
import { TamaguiProvider, type TamaguiProviderProps } from 'tamagui'
import { ToastProvider, ToastViewport } from '@tamagui/toast' // Opcional pero recomendado
import { tamaguiConfig } from './tamagui.config'

export function Provider({ children, ...rest }: Omit<TamaguiProviderProps, 'config'>) {
  const colorScheme = useColorScheme()

  return (
    // Pasamos tamaguiConfig directamente a la prop config
    <TamaguiProvider 
      config={tamaguiConfig} 
      disableInjectCSS 
      defaultTheme={colorScheme === 'dark' ? 'dark' : 'light'}
    >
      <ToastProvider>
        {children}
        
        {/* El Viewport es donde aparecerán las notificaciones de Pideloo */}
        <ToastViewport top="$8" left={0} right={0} />
      </ToastProvider>
    </TamaguiProvider>
  )
}