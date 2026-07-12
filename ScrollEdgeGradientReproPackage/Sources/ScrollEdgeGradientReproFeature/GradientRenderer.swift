import Metal
import QuartzCore
import UIKit

struct GradientGeometry: Equatable, Sendable {
    static let heightFraction: CGFloat = 0.5

    static func frame(viewport: CGRect) -> CGRect {
        CGRect(
            x: viewport.minX,
            y: viewport.minY,
            width: viewport.width,
            height: viewport.height * heightFraction
        )
    }

    static func smoothstep(_ value: CGFloat) -> CGFloat {
        let clamped = min(max(value, 0), 1)
        return clamped * clamped * (3 - 2 * clamped)
    }
}

@MainActor
final class FiniteGradientView: UIView {
    private let gradientView = RotatingMetalGradientView()
    private let fadeView = SmoothFadeView(color: .black)

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.isUserInteractionEnabled = false
        self.clipsToBounds = true
        self.addSubview(self.gradientView)
        self.addSubview(self.fadeView)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.isUserInteractionEnabled = false
        self.clipsToBounds = true
        self.addSubview(self.gradientView)
        self.addSubview(self.fadeView)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.gradientView.frame = self.bounds
        self.fadeView.frame = self.bounds
    }
}

@MainActor
private final class SmoothFadeView: UIView {
    override class var layerClass: AnyClass { CAGradientLayer.self }

    init(color: UIColor) {
        super.init(frame: .zero)
        self.configure(color: color)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.configure(color: .black)
    }

    private func configure(color: UIColor) {
        guard let gradientLayer = self.layer as? CAGradientLayer else { return }
        let samples = stride(from: CGFloat.zero, through: 1, by: 0.1)
        gradientLayer.colors = samples.map { sample in
            color.withAlphaComponent(GradientGeometry.smoothstep(sample)).cgColor
        }
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
    }
}

@MainActor
private final class RotatingMetalGradientView: UIView {
    override class var layerClass: AnyClass { RotatingGradientLayer.self }

    private let displayLinkProxy = DisplayLinkProxy()
    private var displayLink: CADisplayLink?
    private var lastTimestamp: CFTimeInterval?
    private var angle: Float = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if self.window == nil {
            self.displayLink?.invalidate()
            self.displayLink = nil
            self.lastTimestamp = nil
        } else {
            self.startAnimatingIfNeeded()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard let gradientLayer = self.layer as? RotatingGradientLayer else { return }
        let scale = self.window?.screen.scale ?? self.traitCollection.displayScale
        gradientLayer.contentsScale = scale
        gradientLayer.drawableSize = CGSize(
            width: self.bounds.width * scale,
            height: self.bounds.height * scale
        )
        gradientLayer.setNeedsDisplay()
    }

    private func startAnimatingIfNeeded() {
        guard self.displayLink == nil else { return }
        self.displayLinkProxy.target = self
        let displayLink = CADisplayLink(target: self.displayLinkProxy, selector: #selector(DisplayLinkProxy.tick(_:)))
        displayLink.add(to: .main, forMode: .common)
        self.displayLink = displayLink
    }

    fileprivate func updateGradient(displayLink: CADisplayLink) {
        defer { self.lastTimestamp = displayLink.timestamp }
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        guard let lastTimestamp else { return }

        let degreesPerSecond: Float = 12
        let elapsed = Float(displayLink.timestamp - lastTimestamp)
        self.angle += elapsed * degreesPerSecond * .pi / 180

        guard let gradientLayer = self.layer as? RotatingGradientLayer else { return }
        gradientLayer.angle = self.angle
        gradientLayer.setNeedsDisplay()
    }
}

@MainActor
private final class DisplayLinkProxy: NSObject {
    weak var target: RotatingMetalGradientView?

    @objc func tick(_ displayLink: CADisplayLink) {
        self.target?.updateGradient(displayLink: displayLink)
    }
}

private final class RotatingGradientLayer: CAMetalLayer {
    private struct Uniforms {
        var data = SIMD4<Float>(repeating: 0)
        var color1 = SIMD4<Float>(0.99, 0.25, 0.08, 1)
        var color2 = SIMD4<Float>(0.76, 0.17, 0.45, 1)
        var color3 = SIMD4<Float>(0.38, 0.23, 0.65, 1)
        var color4 = SIMD4<Float>(0.08, 0.24, 0.64, 1)
    }

    var angle: Float = 0

    private var commandQueue: MTLCommandQueue?
    private var pipelineState: MTLRenderPipelineState?

    override init() {
        super.init()
        self.configureMetal()
    }

    override init(layer: Any) {
        super.init(layer: layer)
        self.configureMetal()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.configureMetal()
    }

    override func display() {
        guard
            let drawable = self.nextDrawable(),
            let commandQueue = self.commandQueue,
            let pipelineState = self.pipelineState,
            let commandBuffer = commandQueue.makeCommandBuffer()
        else { return }

        let passDescriptor = MTLRenderPassDescriptor()
        passDescriptor.colorAttachments[0].texture = drawable.texture
        passDescriptor.colorAttachments[0].loadAction = .clear
        passDescriptor.colorAttachments[0].storeAction = .store

        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: passDescriptor) else { return }
        var uniforms = Uniforms()
        uniforms.data.x = self.angle
        encoder.setRenderPipelineState(pipelineState)
        encoder.setFragmentBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 0)
        encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    private func configureMetal() {
        guard let device = MTLCreateSystemDefaultDevice() else { return }
        self.device = device
        self.pixelFormat = .bgra8Unorm
        self.framebufferOnly = true
        self.isOpaque = true
        self.needsDisplayOnBoundsChange = true
        self.commandQueue = device.makeCommandQueue()

        do {
            let library = try device.makeLibrary(source: Self.shaderSource, options: nil)
            guard
                let vertexFunction = library.makeFunction(name: "gradientVertex"),
                let fragmentFunction = library.makeFunction(name: "gradientFragment")
            else { return }

            let descriptor = MTLRenderPipelineDescriptor()
            descriptor.vertexFunction = vertexFunction
            descriptor.fragmentFunction = fragmentFunction
            descriptor.colorAttachments[0].pixelFormat = self.pixelFormat
            self.pipelineState = try device.makeRenderPipelineState(descriptor: descriptor)
        } catch {
            assertionFailure("Could not compile the research gradient shader: \(error)")
        }
    }

    private static let shaderSource = """
    #include <metal_stdlib>
    using namespace metal;

    struct VertexOutput {
        float4 position [[position]];
        float2 textureCoordinate;
    };

    struct GradientUniforms {
        float4 data;
        float4 color1;
        float4 color2;
        float4 color3;
        float4 color4;
    };

    vertex VertexOutput gradientVertex(uint vertexID [[vertex_id]]) {
        const float2 positions[4] = {
            float2(-1.0, -1.0), float2(1.0, -1.0),
            float2(-1.0, 1.0), float2(1.0, 1.0)
        };
        const float2 coordinates[4] = {
            float2(0.0, 1.0), float2(1.0, 1.0),
            float2(0.0, 0.0), float2(1.0, 0.0)
        };

        VertexOutput output;
        output.position = float4(positions[vertexID], 0.0, 1.0);
        output.textureCoordinate = coordinates[vertexID];
        return output;
    }

    fragment float4 gradientFragment(
        VertexOutput input [[stage_in]],
        constant GradientUniforms &uniforms [[buffer(0)]]
    ) {
        const float angle = uniforms.data.x;
        const float sine = sin(angle);
        const float cosine = cos(angle);
        const float2 axis = float2(cosine, sine);
        const float2 centered = input.textureCoordinate - 0.5;
        const float position = clamp(dot(centered, axis) * 0.9 + 0.5, 0.0, 1.0);

        float4 color = mix(uniforms.color1, uniforms.color2, smoothstep(0.02, 0.40, position));
        color = mix(color, uniforms.color3, smoothstep(0.28, 0.72, position));
        color = mix(color, uniforms.color4, smoothstep(0.62, 1.0, position));
        return color;
    }
    """
}
