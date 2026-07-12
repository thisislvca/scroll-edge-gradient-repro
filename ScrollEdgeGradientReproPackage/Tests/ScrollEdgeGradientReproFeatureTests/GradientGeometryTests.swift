import CoreGraphics
import Testing
@testable import ScrollEdgeGradientReproFeature

@Test("The finite field is 35 percent of the viewport")
func gradientHeightMatchesReverseEngineeredRatio() {
    let frame = GradientGeometry.frame(
        viewport: CGRect(x: 0, y: 0, width: 390, height: 800),
        contentOffsetY: 0
    )

    #expect(frame.height == 280)
}

@Test("The field moves one point for every positive scroll point")
func gradientTracksPositiveScrollOffset() {
    let frame = GradientGeometry.frame(
        viewport: CGRect(x: 0, y: 0, width: 390, height: 800),
        contentOffsetY: 146
    )

    #expect(frame.minY == -146)
}

@Test("Overscroll does not pull the field downward")
func gradientClampsNegativeScrollOffset() {
    let frame = GradientGeometry.frame(
        viewport: CGRect(x: 0, y: 0, width: 390, height: 800),
        contentOffsetY: -120
    )

    #expect(frame.minY == 0)
}

@Test(arguments: [CGFloat.zero, 0.25, 0.5, 0.75, 1])
func smoothstepStaysWithinUnitRange(value: CGFloat) {
    let result = GradientGeometry.smoothstep(value)
    #expect(result >= 0)
    #expect(result <= 1)
}
