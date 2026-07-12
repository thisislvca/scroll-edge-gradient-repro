import { DarkTheme, ThemeProvider } from 'expo-router/react-navigation';
import { NativeTabs } from 'expo-router/unstable-native-tabs';
import { StatusBar } from 'expo-status-bar';

const theme = {
  ...DarkTheme,
  colors: {
    ...DarkTheme.colors,
    background: '#000000',
    card: '#000000',
  },
};

export const unstable_settings = {
  initialRouteName: '(a-separated)',
};

export default function RootLayout() {
  return (
    <ThemeProvider value={theme}>
      <StatusBar style="light" />
      <NativeTabs tintColor="#30A7FF">
        <NativeTabs.Trigger name="(a-separated)">
          <NativeTabs.Trigger.Icon
            sf={{ default: 'square.3.layers.3d', selected: 'square.3.layers.3d.top.filled' }}
          />
          <NativeTabs.Trigger.Label>Separated</NativeTabs.Trigger.Label>
        </NativeTabs.Trigger>
        <NativeTabs.Trigger name="(b-in-scroll)">
          <NativeTabs.Trigger.Icon sf="rectangle.2.swap" />
          <NativeTabs.Trigger.Label>In-scroll</NativeTabs.Trigger.Label>
        </NativeTabs.Trigger>
      </NativeTabs>
    </ThemeProvider>
  );
}
