import { createFont } from "tamagui"

export const interfonts = createFont({
  family: 'Inter, -apple-system, system-ui, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif',
  size: {
    1: 12,
    2: 14,
    3: 15,
    4: 16,
    5: 20,
    6: 24,
    7: 28,
    8: 36,
    9: 44,
    10: 64,
    true: 14,
  },
  lineHeight: {
    1: 17,
    2: 22,
    3: 25,
    // ... puedes expandir esto
  },
  weight: {
    4: '400',
    6: '600',
    7: '700',
  },
  letterSpacing: {
    4: 0,
    8: -1,
  },
  // Requerido para compatibilidad con Native
  face: {
    400: { normal: 'Inter' },
    600: { normal: 'InterSemiBold' },
    700: { normal: 'InterBold' },
  },
})