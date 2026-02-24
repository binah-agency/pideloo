import { createThemeBuilder } from '@tamagui/theme-builder'

const themesBuilder = createThemeBuilder()
  // 1. Definimos las paletas basadas en la captura Midnight Purple
  .addPalettes({
    dark: [
      '#050505', // 0: Background profundo
      '#111111', // 1: Hover
      '#151515', // 2: Press
      '#191919', // 3: Border
      '#232323', 
      '#282828', 
      '#323232', 
      '#424242', 
      '#666666', 
      '#999999', 
      '#cccccc', 
      '#ffffff'  // 11: Texto principal
    ],
    light: [
      '#ffffff', 
      '#f8f9fa', 
      '#f1f3f5', 
      '#e9ecef', 
      '#dee2e6', 
      '#ced4da', 
      '#adb5bd', 
      '#868e96', 
      '#495057', 
      '#343a40', 
      '#212529', 
      '#050505'
    ],
    // El morado vibrante de Pideloo
    purple: [
      '#120d1d', 
      '#1a132d', 
      '#251b3d', 
      '#31234d', 
      '#423063', 
      '#543d7a', 
      '#6b4e9a', 
      '#8262ba', // 7: Color principal del botón
      '#9d81d4', 
      '#bba7e8', 
      '#dcd1f6', 
      '#f3effd'
    ]
  })
  // 2. Definimos la plantilla con TODOS los tokens para evitar warnings
  .addTemplates({
    base: {
      background: 0,
      backgroundHover: 1,
      backgroundPress: 2,
      backgroundFocus: 1,
      
      color: 11,
      colorHover: 10,
      colorPress: 11,
      colorFocus: 10,
      
      borderColor: 3,
      borderColorHover: 4,
      borderColorPress: 5,
      borderColorFocus: 4,

      // Evita el warning de outlineColor
      outlineColor: 3,
      
      shadowColor: 0,
      placeholderColor: 7,
    },
    // Template para componentes destacados (botones morados)
    accent: {
      background: 7,
      backgroundHover: 8,
      backgroundPress: 9,
      backgroundFocus: 8,
      color: 11,
      borderColor: 9,
      outlineColor: 10,
    }
  })
  // 3. Creamos los temas raíz
  .addThemes({
    light: { template: 'base', palette: 'light' },
    dark: { template: 'base', palette: 'dark' },
  })
  // 4. Creamos los sub-temas (para usar theme="purple")
  .addChildThemes({
    purple: { template: 'accent', palette: 'purple' }
  })

// 5. Construimos y exportamos
// Usamos "as any" para evitar el error ts(2322) de selectionStyles en versiones específicas
export const themes = themesBuilder.build() as any