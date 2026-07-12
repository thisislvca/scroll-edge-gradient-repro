import type { StyleProp, ViewStyle } from 'react-native';

export type ScrollEdgeGradientMode = 'separated' | 'inScroll';

export type ScrollEdgeGradientViewProps = {
  colors: string[];
  heightFraction?: number;
  mode?: ScrollEdgeGradientMode;
  style?: StyleProp<ViewStyle>;
};
