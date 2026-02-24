import { StatusBar } from 'expo-status-bar';
import { TamaguiProvider, YStack, Text, Button } from 'tamagui'
import config from './tamagui.config'

export default function App() {
  return (
    <TamaguiProvider config={config}>
      <YStack flex={1} justifyContent="center" alignItems="center" backgroundColor="$background">
        <Text fontSize="$8" fontWeight="bold" color="$color">
          Hello Tamagui!
        </Text>
        <Button theme="blue" marginTop="$4">
          Press me
        </Button>
        <StatusBar style="auto" />
      </YStack>
    </TamaguiProvider>
  )
}
