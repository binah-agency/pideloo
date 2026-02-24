import { createTokens } from 'tamagui'

// 1. Definimos constantes de color para reutilizar
const colorTokens = {
  // Escala Neutra (Midnight)
  dark1: '#050505',
  dark2: '#111111',
  dark3: '#151515',
  dark4: '#191919',
  
  // Escala Accento (Purple)
  purple1: '#120d1d',
  purple7: '#6b4e9a',
  purple8: '#8262ba',
  purple9: '#9d81d4',

  // Básicos
  white: '#ffffff',
  black: '#000000',
  red: '#ff3b30',
  yellow: '#ffcc00',
  green: '#34c759',
}

export const tokens = createTokens({
  color: {
    ...colorTokens,
    // Shorthands útiles para legibilidad
    brand: colorTokens.purple8,
    background: colorTokens.dark1,
    border: colorTokens.dark4,
  },

  // 2. Escala de Espaciado (Layout y Margenes)
  // Basada en múltiplos de 4px para un ritmo visual perfecto
  space: {
    0: 0,
    0.5: 2,
    1: 4,
    1.5: 6,
    2: 8,
    3: 12,
    4: 16,
    5: 20,
    6: 24,
    8: 32,
    10: 40,
    12: 48,
    16: 64,
    true: 16, // Valor por defecto para props de padding/margin
  },

  // 3. Escala de Tamaños (Componentes y Botones)
  size: {
    0: 0,
    1: 4,
    2: 8,
    3: 12,
    4: 16,
    5: 20,
    6: 24,
    7: 28,
    8: 32,
    10: 40,
    12: 48,
    16: 64,
    true: 44, // Altura estándar para botones/inputs táctiles
  },

  // 4. Radios (Bordes redondeados)
  // Permite desde botones cuadrados hasta cards modernas y pills
  radius: {
    0: 0,
    1: 4,
    2: 8,
    3: 12, // El radio ideal para Cards de Dashboard
    4: 16,
    8: 32,
    true: 12,
    full: 9999, // Para botones tipo "Pill" o Avatares
  },

  // 5. Z-Index (Capas de la UI)
  zIndex: {
    0: 0,
    1: 100,
    2: 200,
    3: 300,
    4: 400,
    5: 500,
    modal: 1000,
    overlay: 900,
    tooltip: 1100,
    true: 0,
  },
})