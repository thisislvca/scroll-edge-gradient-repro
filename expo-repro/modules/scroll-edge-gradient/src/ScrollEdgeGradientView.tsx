import { requireNativeView } from 'expo';
import * as React from 'react';

import { ScrollEdgeGradientViewProps } from './ScrollEdgeGradient.types';

const NativeView: React.ComponentType<ScrollEdgeGradientViewProps> = requireNativeView('ScrollEdgeGradient');

export default function ScrollEdgeGradientView(props: ScrollEdgeGradientViewProps) {
  return (
    <NativeView
      heightFraction={0.75}
      mode="separated"
      {...props}
    />
  );
}
