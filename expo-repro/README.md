# Expo / React Native Repro

This is the React Native counterpart to the repository's native UIKit research app. It demonstrates the same two compositing arrangements through one Expo app:

- **Separated** keeps the animated Metal field outside the registered React Native scroll view.
- **In-scroll** places the identical field inside the scroll view so opaque card pixels can replace it before UIKit applies the edge effect.

The UI is React Native. The source separation, scroll registration, and Metal renderer live in a local Expo module under `modules/scroll-edge-gradient`.

## Run

This app contains custom Swift code and cannot run in Expo Go.

```sh
bun install
bunx expo prebuild --platform ios
bun run ios
```

To start Metro separately after the development build already exists:

```sh
bun start
```

## React API

Place the native anchor inside the scroll view whose edge effect should be coordinated:

```tsx
<ScrollView contentInsetAdjustmentBehavior="automatic">
  <ScrollEdgeGradientView
    colors={['#FC4A20', '#C42E73', '#673DA6', '#1645A4']}
    heightFraction={0.75}
    mode="separated"
  />
  <OpaqueContent />
</ScrollView>
```

The `inScroll` mode exists for the failure-control tab. Production use should select `separated`.

## Requirements

- Bun
- Xcode 26 or newer
- iOS 26 Simulator or device for `UIScrollEdgeEffect`
- An Expo development build
