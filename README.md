# Scroll Edge Gradient Repro

A small iOS 26 research app that reproduces the colorful, animated scroll-edge treatment seen in Apple Health's Summary tab.

The important trick is not a stronger blur or a tinted navigation bar. The animated field and the scrolling foreground must remain separate compositing sources:

```text
UIViewController root (black)
├── finite animated gradient view
└── transparent UICollectionView
    └── opaque cards, headings, and charts
```

When an opaque card reaches the compact navigation region, UIKit can soften the collection-view foreground while the independently rendered gradient remains visible behind it. The gradient then moves upward with the scroll offset until its finite edge passes the navigation region and reveals black.

## What the app demonstrates

Use the sliders button in the navigation bar to switch between:

- **Source separated**: the reconstructed Health-style hierarchy.
- **Flattened baseline**: the gradient is assigned to the collection view itself, demonstrating why an ordinary background often collapses into a dark card blur.

Scroll slowly until the first opaque card passes beneath the compact `Summary` title. Continue scrolling to see the finite color field transition completely to black.

For scripted capture, launch with `--flattened` to start directly in the baseline mode.

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

## Exact reconstruction versus approximation

The view hierarchy, 35-percent geometry, scroll equation, four-color uniform layout, 12-degree-per-second animation rate, and smoothstep fade are direct reconstructions of observable implementation details.

The Metal shader in this repository is a clean-room approximation. Apple's compiled shader exposes four color inputs and uses trigonometric rotation, a directional dot product, clamping, and color mixing, but its original source code is not available. This project recreates that behavior without copying Apple source or private APIs.

## Code map

- `GradientRenderer.swift`: `CAMetalLayer`, runtime Metal shader, display-link animation, finite smooth fade, and geometry math.
- `HealthGradientViewController.swift`: source-separated UIKit hierarchy, collection-view cards, scroll synchronization, and comparison mode.
- `ContentView.swift`: minimal SwiftUI bridge that hosts the UIKit navigation controller.
- `GradientGeometryTests.swift`: tests for the recovered geometry and fade curve.

## Requirements

- Xcode 26 or newer
- iOS 26 Simulator or device

Open `ScrollEdgeGradientRepro.xcworkspace`, select the `ScrollEdgeGradientRepro` scheme, and run.

## Verification

The repro is tested on an iPhone 17 Pro simulator running iOS 26.3:

- clean Debug build and launch;
- package geometry tests;
- UI automation for launch and scrolling;
- visual captures at the large-title state, colored compact-title state, and black cutoff state.

## Research disclaimer

This project is an independent interoperability and UI-behavior study. It is not affiliated with or endorsed by Apple. Apple, Apple Health, iPhone, UIKit, and Xcode are trademarks of Apple Inc.

## License

MIT. See `LICENSE`.
