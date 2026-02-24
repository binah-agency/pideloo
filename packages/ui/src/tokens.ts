import { createTokens } from 'tamagui'

export const tokens = createTokens({
  color: {
    white: '#fff',
    black: '#000',
    gray1: '#f2f2f2',
    gray2: '#e2e2e2',
    gray3: '#ccc',
    blue1: '#007aff',
    blue2: '#0056b3',
    red: '#ff3b30',
  },
  space: {
    0: 0,
    1: 4,
    2: 8,
    4: 16,
    true: 8, // Valor por defecto
  },
  size: {
    0: 0,
    1: 4,
    2: 8,
    4: 16,
    true: 8,
  },
  radius: {
    0: 0,
    1: 4,
    2: 8,
    true: 4,
  },
  zIndex: {
    0: 0,
    true: 0,
  },
})