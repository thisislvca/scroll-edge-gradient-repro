import CoreGraphics
import Testing
@testable import ScrollEdgeGradientReproFeature

@Test("The demo field is 50 percent of the viewport")
func gradientHeightMatchesDemoRatio() {
    let frame = GradientGeometry.frame(
        viewport: CGRect(x: 0, y: 0, width: 390, height: 800)
    )

    #expect(frame.height == 400)
}

@Test("The demo field stays pinned to the viewport top")
func gradientStaysPinnedToViewportTop() {
    let frame = GradientGeometry.frame(
        viewport: CGRect(x: 0, y: 0, width: 390, height: 800)
    )

    #expect(frame.minY == 0)
}

@Test(arguments: [CGFloat.zero, 0.25, 0.5, 0.75, 1])
func smoothstepStaysWithinUnitRange(value: CGFloat) {
    let result = GradientGeometry.smoothstep(value)
    #expect(result >= 0)
    #expect(result <= 1)
}
