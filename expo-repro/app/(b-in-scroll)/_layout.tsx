import { Stack } from 'expo-router/stack';

export default function InScrollLayout() {
  return (
    <Stack
      screenOptions={{
        contentStyle: { backgroundColor: '#000000' },
        headerLargeStyle: { backgroundColor: 'transparent' },
        headerLargeTitle: true,
        headerLargeTitleShadowVisible: false,
        headerShadowVisible: false,
        headerStyle: { backgroundColor: 'transparent' },
        headerTransparent: true,
        scrollEdgeEffects: { top: 'automatic' },
      }}
    >
      <Stack.Screen name="index" options={{ title: 'In-scroll Control' }} />
    </Stack>
  );
}
