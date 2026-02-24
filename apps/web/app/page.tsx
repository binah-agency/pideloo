'use client'

import { YStack, XStack, H2, Button, Card, Text, Paragraph } from 'tamagui'
import { Activity, ArrowUpRight } from '@tamagui/lucide-icons'

export default function Dashboard() {
  return (
    <YStack f={1} bg="$background" p="$6" gap="$6" ai="center">
      
      {/* Header con Shorthands */}
      <XStack w="100%" jc="space-between" ai="center" maxW={1000}>
        <YStack>
          <H2 fow="700">Dashboard</H2>
          <Paragraph o={0.6}>Welcome back, Pideloo Admin</Paragraph>
        </YStack>
        <Button icon={Activity} theme="purple" br="$10" animation="quick" hoverStyle={{ scale: 0.95 }}>
          Live View
        </Button>
      </XStack>

      {/* Grid de Cards Responsivo */}
      <XStack gap="$4" fw="wrap" jc="center" w="100%" maxW={1000}>
        {[1, 2, 3].map((i) => (
          <Card 
            key={i}
            f={1} 
            fb={300} 
            p="$5" 
            br="$4" 
            bordered 
            bg="$backgroundHover"
            animation="bouncy"
            hoverStyle={{ y: -5, bc: '$backgroundFocus' }}
            pressStyle={{ scale: 0.98 }}
          >
            <YStack gap="$2">
              <XStack jc="space-between">
                <Text color="$purple" fow="700" lts={1} fos="$2">REVENUE</Text>
                <ArrowUpRight size={20} color="$purple" />
              </XStack>
              <H2>$42.3K</H2>
              <Paragraph o={0.5} fos="$1">+12% from last month</Paragraph>
            </YStack>
          </Card>
        ))}
      </XStack>

    </YStack>
  )
}