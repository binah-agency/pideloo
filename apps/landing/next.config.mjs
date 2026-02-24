import { withTamagui } from '@tamagui/next-plugin';

const tamaguiPlugin = withTamagui({
  config: '../../packages/ui/src/tamagui.config.ts',
  components: ['tamagui', '@pideloo/ui'],
  appDir: true,
});

/** @type {import('next').NextConfig} */
const nextConfig = {
  // ¡ESTA LÍNEA ES LA MAGIA QUE RESUELVE EL ERROR!
  transpilePackages: ['@pideloo/ui'], 
};

export default tamaguiPlugin(nextConfig);