# Scroll Edge Gradient Repro

An iOS 26 research repository that reproduces the colorful, animated scroll-edge treatment seen in Apple Health's Summary tab in two apps:

- a native UIKit/SwiftUI reference app;
- an Expo/React Native app backed by a local Swift module.

## See the difference

The same page is shown in both configurations. In **Separated**, the compact title retains the moving color field behind opaque content. In **In-scroll**, the gradient shares the foreground's compositing source, so the compact edge receives the card's dark pixels instead.

[scroll-edge-gradient-comparison.webm](https://github.com/user-attachments/assets/8421b890-4b94-414b-8369-e655c64ace9b)

The important trick is not a stronger blur or a tinted navigation bar. The animated field and the scrolling foreground must remain separate compositing sources:

```text
UIViewController root (black)
├── finite animated gradient view
└── transparent UIScrollView
    └── opaque cards, headings, and charts
```

When an opaque card reaches the compact navigation region, UIKit can soften the scrolling foreground while the independently rendered gradient remains visible behind it. The finite field moves upward with the scroll until its lower edge passes the compact title and reveals black.

## What the apps demonstrate

Use the two bottom tabs to switch between:

- **Separated**: the reconstructed two-source hierarchy.
- **In-scroll**: the same field is nested inside scroll content with the opaque cards, demonstrating the source-flattening failure caused by that hierarchy.

Each app contains the same two-tab experiment. Every tab is a scrollable explainer with the compositing model, observed values, and a concrete visual test. Scroll slowly until the first opaque card passes beneath the compact title; then switch tabs and compare the top edge.

For scripted capture, launch with `--in-scroll` to start directly in the control.

## Reverse-engineered findings

These details were observed in the iOS 26.3 Simulator version of Apple Health through accessibility inspection, Mach-O metadata, symbol inspection, Metal-library reflection, and disassembly:

- The Summary screen is backed by a native `UICollectionView`.
- `SummaryFeedViewController` stores a `gradientView`, `gradientSubscriber`, and `gradientColorProvider`.
- HealthExperienceUI contains `ProfileGradientView`, `ProfileGradientWithFadeView`, `GradientLayer`, and `GradientUniforms`.
- `ProfileGradientView` uses a custom `CAMetalLayer` and a four-color Metal fragment shader.
- The uniform block is 80 bytes: one `float4` data vector plus four `float4` colors.
- A `CADisplayLink` advances the shader angle at 12 degrees per second.
- The finite gradient height is 35 percent of the controller viewport.
- Its vertical origin is `-max(contentOffset.y, 0)`.
- The fade is sampled in 0.1 increments using `t² × (3 − 2t)` smoothstep alpha.
- The gradient is inserted behind the scrolling foreground with a negative layer position.
- The Health binary contains `contentScrollViewForEdge:` plumbing consistent with explicit UIKit edge registration; this repro uses the public `setContentScrollView(_:for:)` API.

For clearer side-by-side filming, this demo deliberately extends the visible field to 75 percent of the viewport while retaining the observed scroll translation and spatial fade. Health's observed implementation uses a 35-percent field.

## Exact reconstruction versus approximation

The view hierarchy, scroll equation, four-color uniform layout, 12-degree-per-second animation rate, and smoothstep fade are direct reconstructions of observable implementation details. Only the demo's 75-percent field height intentionally differs from Health's observed 35-percent value.

The Metal shader in this repository is a clean-room approximation. Apple's compiled shader exposes four color inputs and uses trigonometric rotation, a directional dot product, clamping, and color mixing, but its original source code is not available. This project recreates that behavior without copying Apple source or private APIs.

## Code map

- `GradientRenderer.swift`: `CAMetalLayer`, runtime Metal shader, display-link animation, finite smooth fade, and geometry math.
- `HealthGradientViewController.swift`: two UIKit experiments, their scrollable explainer content, and scroll synchronization.
- `ContentView.swift`: SwiftUI bridge that hosts the two-tab UIKit comparison.
- `expo-repro/`: the single Expo/React Native app.
- `expo-repro/modules/scroll-edge-gradient/`: the Apple-only local Expo module that bridges UIKit scroll registration and the Metal field.
- `expo-repro/components/repro-screen.tsx`: the shared React Native explainer UI for both Expo tabs.

## Requirements

- Xcode 26 or newer
- iOS 26 Simulator or device

### Native app

Open `ScrollEdgeGradientRepro.xcworkspace`, select the `ScrollEdgeGradientRepro` scheme, and run.

### Expo app

The Expo app requires a development build because Expo Go cannot include its local Swift module:

```sh
cd expo-repro
bun install
bunx expo prebuild --platform ios
bun run ios
```

See `expo-repro/README.md` for the module API and project-specific notes.

## Verification

Both apps have been built and run on an iPhone 17 Pro simulator running iOS 26.3. Their large-title, colored compact-title, in-scroll failure, stable tab-bar, and black-cutoff states were checked directly in the simulator.

## Research disclaimer

This project is an independent interoperability and UI-behavior study. It is not affiliated with or endorsed by Apple. Apple, Apple Health, iPhone, UIKit, and Xcode are trademarks of Apple Inc.

## License

MIT. See `LICENSE`.
