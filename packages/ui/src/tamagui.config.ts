'use client'

import { config } from '@tamagui/config/v3'
import { createTamagui } from 'tamagui'
import { themes } from './themes'
import { tokens } from './tokens'
import { shorthands } from './shorthands'
import { interfonts } from './fonts'
import { mediaQueries } from './mediaQueries'

export const tamaguiConfig = createTamagui({
  ...config,
  themes,
  tokens,
  shorthands,
  fonts: {
    body: interfonts,
  },
  mediaQueries,
  
})

export default tamaguiConfig

export type AppConfig = typeof tamaguiConfig

declare module 'tamagui' {
  interface TamaguiCustomConfig extends AppConfig {}
}