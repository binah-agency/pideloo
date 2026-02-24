'use client'

import React from 'react'
import { useServerInsertedHTML } from 'next/navigation'
// Asegúrate de que este import sea exacto
import { tamaguiConfig } from '@pideloo/ui' 

export default function TamaguiRegistry({ children }: { children: React.ReactNode }) {
  useServerInsertedHTML(() => {
    // Si tamaguiConfig no cargó bien, devolvemos null para no romper el render
    if (!tamaguiConfig) return null
    return <style dangerouslySetInnerHTML={{ __html: tamaguiConfig.getCSS() }} />
  })

  return <>{children}</>
}