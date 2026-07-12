import ExpoModulesCore
import Metal
import UIKit

final class ScrollEdgeGradientView: ExpoView {
  var colors: [String] = [] {
    didSet {
      backdropLayer.colors = colors.compactMap(UIColor.init(scrollEdgeHex:))
    }
  }

  var heightFraction: Double = 0.75 {
    didSet {
      backdropLayer.heightFraction = min(max(CGFloat(heightFraction), 0.2), 1.5)
    }
  }

  var mode = "separated" {
    didSet {
      guard oldValue != mode, window != nil else { return }
      detachBackdrop()
      DispatchQueue.main.async { [weak self] in
        self?.attachBackdropIfPossible()
      }
    }
  }

  private let backdropLayer = ScrollEdgeGradientBackdropLayer()
  private weak var backdropContainerView: UIView?
  private weak var foregroundView: UIView?
  private weak var observedScrollView: UIScrollView?
  private var contentOffsetObservation: NSKeyValueObservation?
  private weak var navigationItem: UINavigationItem?
  private var originalStandardAppearance: UINavigationBarAppearance?
  private var originalCompactAppearance: UINavigationBarAppearance?
  private var originalScrollEdgeAppearance: UINavigationBarAppearance?
  private var originalTopEdgeEffectHidden: Bool?

  required init(appContext: AppContext? = nil) {
    super.init(appContext: appContext)
    isUserInteractionEnabled = false
    isHidden = true
  }

  override func didMoveToWindow() {
    super.didMoveToWindow()

    guard window != nil else {
      detachBackdrop()
      return
    }

    DispatchQueue.main.async { [weak self] in
      self?.attachBackdropIfPossible()
    }
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    syncBackdropFrame()
  }

  private var usesSeparatedSource: Bool {
    mode != "inScroll"
  }

  private func attachBackdropIfPossible() {
    guard
      observedScrollView == nil,
      let scrollView = firstSuperview(of: UIScrollView.self),
      let viewController = nearestViewController(),
      let foregroundView = directChild(containing: scrollView, in: viewController.view)
    else { return }

    observedScrollView = scrollView
    self.foregroundView = foregroundView
    backdropLayer.heightFraction = min(max(CGFloat(heightFraction), 0.2), 1.5)

    if usesSeparatedSource {
      backdropContainerView = viewController.view
      backdropLayer.frame = viewController.view.layer.bounds
      viewController.view.layer.insertSublayer(backdropLayer, below: foregroundView.layer)
    } else {
      backdropContainerView = scrollView
      scrollView.layer.insertSublayer(backdropLayer, at: 0)
    }

    backdropLayer.startAnimating()
    configureNavigationAppearances(for: viewController)

    if #available(iOS 26.0, *) {
      viewController.setContentScrollView(scrollView, for: .top)
      originalTopEdgeEffectHidden = scrollView.topEdgeEffect.isHidden
      scrollView.topEdgeEffect.style = .automatic
      scrollView.topEdgeEffect.isHidden = false
    }

    contentOffsetObservation = scrollView.observe(
      \.contentOffset,
      options: [.initial, .new]
    ) { [weak self] scrollView, _ in
      DispatchQueue.main.async {
        self?.updateBackdrop(using: scrollView)
      }
    }
  }

  private func updateBackdrop(using scrollView: UIScrollView) {
    syncBackdropFrame()
    let distance = max(0, scrollView.contentOffset.y + scrollView.adjustedContentInset.top)
    backdropLayer.scrollDistance = usesSeparatedSource ? distance : 0
  }

  private func syncBackdropFrame() {
    guard let backdropContainerView, let scrollView = observedScrollView else { return }
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    backdropLayer.contentsScale = backdropContainerView.traitCollection.displayScale

    if usesSeparatedSource {
      backdropLayer.frame = backdropContainerView.layer.bounds
    } else {
      backdropLayer.frame = CGRect(
        x: 0,
        y: -scrollView.adjustedContentInset.top,
        width: scrollView.bounds.width,
        height: scrollView.bounds.height
      )
    }

    CATransaction.commit()
  }

  private func configureNavigationAppearances(for viewController: UIViewController) {
    let item = viewController.navigationItem
    navigationItem = item
    originalStandardAppearance = item.standardAppearance
    originalCompactAppearance = item.compactAppearance
    originalScrollEdgeAppearance = item.scrollEdgeAppearance

    let fallback = viewController.navigationController?.navigationBar.standardAppearance
      ?? UINavigationBarAppearance()
    item.standardAppearance = transparentCopy(of: item.standardAppearance ?? fallback)
    item.compactAppearance = transparentCopy(of: item.compactAppearance ?? fallback)
    item.scrollEdgeAppearance = transparentCopy(of: item.scrollEdgeAppearance ?? fallback)
  }

  private func transparentCopy(
    of appearance: UINavigationBarAppearance
  ) -> UINavigationBarAppearance {
    let copy = appearance.copy()
    copy.backgroundColor = .clear
    copy.backgroundEffect = nil
    copy.shadowColor = .clear
    copy.backgroundImage = nil
    return copy
  }

  private func detachBackdrop() {
    contentOffsetObservation?.invalidate()
    contentOffsetObservation = nil
    backdropLayer.stopAnimating()

    if #available(iOS 26.0, *) {
      observedScrollView?.topEdgeEffect.isHidden = originalTopEdgeEffectHidden ?? false
    }

    navigationItem?.standardAppearance = originalStandardAppearance
    navigationItem?.compactAppearance = originalCompactAppearance
    navigationItem?.scrollEdgeAppearance = originalScrollEdgeAppearance
    observedScrollView = nil
    backdropContainerView = nil
    foregroundView = nil
    navigationItem = nil
    originalStandardAppearance = nil
    originalCompactAppearance = nil
    originalScrollEdgeAppearance = nil
    originalTopEdgeEffectHidden = nil
    backdropLayer.removeFromSuperlayer()
  }

  private func nearestViewController() -> UIViewController? {
    var responder: UIResponder? = self
    while let current = responder {
      if let viewController = current as? UIViewController {
        return viewController
      }
      responder = current.next
    }
    return nil
  }

  private func firstSuperview<T: UIView>(of type: T.Type) -> T? {
    var view = superview
    while let current = view {
      if let match = current as? T {
        return match
      }
      view = current.superview
    }
    return nil
  }

  private func directChild(containing descendant: UIView, in parent: UIView) -> UIView? {
    var candidate = descendant
    while let superview = candidate.superview, superview !== parent {
      candidate = superview
    }
    return candidate.superview === parent ? candidate : nil
  }
}

private final class ScrollEdgeGradientBackdropLayer: CALayer {
  var colors: [UIColor] = [] {
    didSet { metalLayer.colors = colors }
  }

  var heightFraction: CGFloat = 0.75 {
    didSet { setNeedsLayout() }
  }

  var scrollDistance: CGFloat = 0 {
    didSet { setNeedsLayout() }
  }

  private let metalLayer = ScrollEdgeMetalGradientLayer()
  private let fadeLayer = CAGradientLayer()
  private let displayLinkProxy = ScrollEdgeDisplayLinkProxy()
  private var displayLink: CADisplayLink?
  private var lastTimestamp: CFTimeInterval?
  private var angle: Float = 0

  override init() {
    super.init()
    backgroundColor = UIColor.black.cgColor
    masksToBounds = true
    addSublayer(metalLayer)
    addSublayer(fadeLayer)
    configureFade()
  }

  override init(layer: Any) {
    super.init(layer: layer)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func startAnimating() {
    guard displayLink == nil else { return }
    displayLinkProxy.target = self
    let link = CADisplayLink(
      target: displayLinkProxy,
      selector: #selector(ScrollEdgeDisplayLinkProxy.tick(_:))
    )
    link.add(to: .main, forMode: .common)
    displayLink = link
    metalLayer.setNeedsDisplay()
  }

  func stopAnimating() {
    displayLink?.invalidate()
    displayLink = nil
    lastTimestamp = nil
  }

  fileprivate func updateGradient(displayLink: CADisplayLink) {
    defer { lastTimestamp = displayLink.timestamp }
    guard !UIAccessibility.isReduceMotionEnabled else { return }
    guard let lastTimestamp else { return }

    let degreesPerSecond: Float = 12
    let elapsed = Float(displayLink.timestamp - lastTimestamp)
    angle += elapsed * degreesPerSecond * .pi / 180
    metalLayer.angle = angle
    metalLayer.setNeedsDisplay()
  }

  override func layoutSublayers() {
    super.layoutSublayers()
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    let fieldFrame = CGRect(
      x: 0,
      y: -scrollDistance,
      width: bounds.width,
      height: bounds.height * heightFraction
    )
    metalLayer.frame = fieldFrame
    fadeLayer.frame = fieldFrame
    metalLayer.contentsScale = contentsScale
    metalLayer.drawableSize = CGSize(
      width: fieldFrame.width * contentsScale,
      height: fieldFrame.height * contentsScale
    )
    metalLayer.setNeedsDisplay()
    CATransaction.commit()
  }

  private func configureFade() {
    let samples = stride(from: CGFloat.zero, through: 1, by: 0.1)
    fadeLayer.colors = samples.map { sample in
      UIColor.black.withAlphaComponent(Self.smoothstep(sample)).cgColor
    }
    fadeLayer.startPoint = CGPoint(x: 0.5, y: 0)
    fadeLayer.endPoint = CGPoint(x: 0.5, y: 1)
  }

  private static func smoothstep(_ value: CGFloat) -> CGFloat {
    let clamped = min(max(value, 0), 1)
    return clamped * clamped * (3 - 2 * clamped)
  }
}

private final class ScrollEdgeDisplayLinkProxy: NSObject {
  weak var target: ScrollEdgeGradientBackdropLayer?

  @objc func tick(_ displayLink: CADisplayLink) {
    target?.updateGradient(displayLink: displayLink)
  }
}

private final class ScrollEdgeMetalGradientLayer: CAMetalLayer {
  private struct Uniforms {
    var data = SIMD4<Float>(repeating: 0)
    var color1 = SIMD4<Float>(0.99, 0.25, 0.08, 1)
    var color2 = SIMD4<Float>(0.76, 0.17, 0.45, 1)
    var color3 = SIMD4<Float>(0.38, 0.23, 0.65, 1)
    var color4 = SIMD4<Float>(0.08, 0.24, 0.64, 1)
  }

  var angle: Float = 0
  var colors: [UIColor] = [] {
    didSet { setNeedsDisplay() }
  }

  private var commandQueue: MTLCommandQueue?
  private var pipelineState: MTLRenderPipelineState?

  override init() {
    super.init()
    configureMetal()
  }

  override init(layer: Any) {
    super.init(layer: layer)
    configureMetal()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    configureMetal()
  }

  override func display() {
    guard
      let drawable = nextDrawable(),
      let commandQueue,
      let pipelineState,
      let commandBuffer = commandQueue.makeCommandBuffer()
    else { return }

    let passDescriptor = MTLRenderPassDescriptor()
    passDescriptor.colorAttachments[0].texture = drawable.texture
    passDescriptor.colorAttachments[0].loadAction = .clear
    passDescriptor.colorAttachments[0].storeAction = .store

    guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: passDescriptor) else {
      return
    }
    var uniforms = makeUniforms()
    uniforms.data.x = angle
    encoder.setRenderPipelineState(pipelineState)
    encoder.setFragmentBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 0)
    encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
    encoder.endEncoding()
    commandBuffer.present(drawable)
    commandBuffer.commit()
  }

  private func makeUniforms() -> Uniforms {
    guard let first = colors.first else { return Uniforms() }
    let second = colors.dropFirst().first ?? first
    let third = colors.dropFirst(2).first ?? second
    let fourth = colors.dropFirst(3).first ?? third
    return Uniforms(
      color1: first.scrollEdgeSIMD,
      color2: second.scrollEdgeSIMD,
      color3: third.scrollEdgeSIMD,
      color4: fourth.scrollEdgeSIMD
    )
  }

  private func configureMetal() {
    guard let device = MTLCreateSystemDefaultDevice() else { return }
    self.device = device
    pixelFormat = .bgra8Unorm
    framebufferOnly = true
    isOpaque = true
    needsDisplayOnBoundsChange = true
    commandQueue = device.makeCommandQueue()

    do {
      let library = try device.makeLibrary(source: Self.shaderSource, options: nil)
      guard
        let vertexFunction = library.makeFunction(name: "gradientVertex"),
        let fragmentFunction = library.makeFunction(name: "gradientFragment")
      else { return }

      let descriptor = MTLRenderPipelineDescriptor()
      descriptor.vertexFunction = vertexFunction
      descriptor.fragmentFunction = fragmentFunction
      descriptor.colorAttachments[0].pixelFormat = pixelFormat
      pipelineState = try device.makeRenderPipelineState(descriptor: descriptor)
    } catch {
      assertionFailure("Could not compile the scroll-edge gradient shader: \(error)")
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

private extension UIColor {
  convenience init?(scrollEdgeHex hex: String) {
    let value = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    guard value.count == 6, let integer = UInt64(value, radix: 16) else { return nil }
    self.init(
      red: CGFloat((integer >> 16) & 0xFF) / 255,
      green: CGFloat((integer >> 8) & 0xFF) / 255,
      blue: CGFloat(integer & 0xFF) / 255,
      alpha: 1
    )
  }

  var scrollEdgeSIMD: SIMD4<Float> {
    var red: CGFloat = 0
    var green: CGFloat = 0
    var blue: CGFloat = 0
    var alpha: CGFloat = 0
    getRed(&red, green: &green, blue: &blue, alpha: &alpha)
    return SIMD4(Float(red), Float(green), Float(blue), Float(alpha))
  }
}
