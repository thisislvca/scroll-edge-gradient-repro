// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ScrollEdgeGradientReproFeature",
    platforms: [.iOS("26.0")],
    products: [
        .library(
            name: "ScrollEdgeGradientReproFeature",
            targets: ["ScrollEdgeGradientReproFeature"]
        ),
    ],
    targets: [
        .target(
            name: "ScrollEdgeGradientReproFeature"
        ),
    ]
)
