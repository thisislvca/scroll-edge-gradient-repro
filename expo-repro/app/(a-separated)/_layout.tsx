import { Stack } from 'expo-router/stack';

export default function SeparatedLayout() {
  return (
    <Stack
      screenOptions={{
        contentStyle: { backgroundColor: 'transparent' },
        headerLargeStyle: { backgroundColor: 'transparent' },
        headerLargeTitle: true,
        headerLargeTitleShadowVisible: false,
        headerShadowVisible: false,
        headerStyle: { backgroundColor: 'transparent' },
        headerTransparent: true,
        scrollEdgeEffects: { top: 'automatic' },
      }}
    >
      <Stack.Screen name="index" options={{ title: 'Separated' }} />
    </Stack>
  );
}
