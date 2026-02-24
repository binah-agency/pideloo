'use client'

import { Button as TamaguiButton, styled } from 'tamagui'

export const Button = styled(TamaguiButton, {
  name: 'CustomButton',
  backgroundColor: '$blue10',
  color: 'white',
  hoverStyle: {
    backgroundColor: '$blue11',
  },
  pressStyle: {
    backgroundColor: '$blue9',
  },
})