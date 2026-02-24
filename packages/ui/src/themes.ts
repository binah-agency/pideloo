'use client'

import { createTamagui, createFont } from 'tamagui'
import { shorthands } from './shorthands'
import { themes } from './themes'
import { tokens } from './tokens'
import { animations } from './animations'

// Fuente tipo Dashboard (Inter-like)
const interFont = createFont({
  family: 'Inter, Helvetica, Arial, sans-serif',
  size: { 1: 12, 2: 14, 3: 15, 4: 16, 5: 20, 6: 24, 9: 42 },
  lineHeight: { 1: 17, 2: 22, 3: 25 },
  weight: { 4: '400', 6: '600', 7: '700' },
  letterSpacing: { 4: 0, 8: -1 },
})

export const tamaguiConfig = createTamagui({
  animations,
  shorthands,
  themes,
  tokens,
  fonts: {
    heading: interFont,
    body: interFont,
  },
  // Responsive Design
  media: {
    xs: { maxWidth: 660 },
    sm: { maxWidth: 800 },
    md: { maxWidth: 1020 },
    lg: { maxWidth: 1280 },
    xl: { maxWidth: 1420 },
    gtXs: { minWidth: 660 + 1 },
    gtSm: { minWidth: 800 + 1 },
    gtMd: { minWidth: 1020 + 1 },
    gtLg: { minWidth: 1280 + 1 },
    short: { maxHeight: 820 },
    tall: { minHeight: 820 },
    hoverNone: { hover: 'none' },
    pointerCoarse: { pointer: 'coarse' },
  },
})

export type AppConfig = typeof tamaguiConfig
declare module 'tamagui' {
  interface TamaguiCustomConfig extends AppConfig {}
}

export default tamaguiConfig