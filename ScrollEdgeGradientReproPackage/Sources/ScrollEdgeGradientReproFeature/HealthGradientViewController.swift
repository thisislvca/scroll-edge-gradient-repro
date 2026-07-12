import SwiftUI
import UIKit

enum GradientExperiment: Int, CaseIterable {
    case separated
    case flattened

    var tabTitle: String {
        switch self {
        case .separated: "Separated"
        case .flattened: "Flattened"
        }
    }

    var tabImage: String {
        switch self {
        case .separated: "square.3.layers.3d"
        case .flattened: "square.stack.3d.down.right"
        }
    }

    var accent: Color {
        switch self {
        case .separated: .cyan
        case .flattened: .orange
        }
    }

    var badge: String {
        switch self {
        case .separated: "WORKING MODEL"
        case .flattened: "FAILURE CONTROL"
        }
    }

    var heroTitle: String {
        switch self {
        case .separated: "The gradient remains visible"
        case .flattened: "The gradient disappears"
        }
    }

    var heroDetail: String {
        switch self {
        case .separated:
            "The color field and scrolling content stay in separate compositing planes."
        case .flattened:
            "The field is ordinary scroll content, so an opaque surface replaces its pixels."
        }
    }

    var result: String {
        switch self {
        case .separated: "Color survives beneath the compact title"
        case .flattened: "The compact title receives a dark blur"
        }
    }
}

private struct LabStep {
    let number: String
    let title: String
    let detail: String
}

private enum LabItem {
    case hero
    case specimen
    case section(kicker: String, title: String)
    case step(LabStep)
    case layers
    case equation
    case metrics
    case note

    var height: CGFloat {
        switch self {
        case .hero: 188
        case .specimen: 218
        case .section: 66
        case .step: 134
        case .layers: 300
        case .equation: 190
        case .metrics: 222
        case .note: 166
        }
    }
}

@MainActor
final class HealthGradientViewController: UIViewController {
    private let experiment: GradientExperiment
    private let finiteGradientView = FiniteGradientView()
    private let collectionView: UICollectionView

    private var items: [LabItem] {
        var result: [LabItem] = [.hero]
        if self.experiment == .flattened {
            result.append(.specimen)
        }
        result += [
            .section(kicker: "01 · RUN THE TEST", title: "Watch the compact title"),
            .step(LabStep(
                number: "1",
                title: "Scroll a solid card upward",
                detail: "Stop when its top edge passes beneath the minimized navigation title."
            )),
            .step(LabStep(
                number: "2",
                title: "Track the orange, purple, and blue",
                detail: self.experiment == .separated
                    ? "Their positions remain visible while the foreground softens."
                    : "They vanish when the opaque card becomes the edge effect's input."
            )),
            .section(kicker: "02 · COMPOSITING", title: "What the edge receives"),
            .layers,
            .equation,
            .section(kicker: "03 · GEOMETRY", title: "A finite, moving field"),
            .metrics,
            .section(kicker: "04 · TAKEAWAY", title: "The blur is not the trick"),
            .note,
        ]
        return result
    }

    init(experiment: GradientExperiment) {
        self.experiment = experiment
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 8, left: 18, bottom: 120, right: 18)
        self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Scroll Edge Lab"
        self.view.backgroundColor = .black
        self.navigationItem.largeTitleDisplayMode = .always
        self.configureCollectionView()
        self.installExperimentComposition()
        self.setContentScrollView(self.collectionView, for: .top)
        self.collectionView.topEdgeEffect.style = .automatic
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.collectionView.frame = self.view.bounds
        self.layoutGradient()
    }

    private func configureCollectionView() {
        self.collectionView.backgroundColor = .clear
        self.collectionView.alwaysBounceVertical = true
        self.collectionView.contentInsetAdjustmentBehavior = .automatic
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.accessibilityIdentifier = "research.collection.\(self.experiment.rawValue)"
        self.collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "LabCell")
        self.view.addSubview(self.collectionView)
    }

    private func installExperimentComposition() {
        guard self.experiment == .separated else { return }

        // Keep the field above the root view's black backing layer, but below the
        // transparent scrolling foreground. A negative zPosition can place it
        // behind the root layer itself and make it disappear on some layouts.
        self.finiteGradientView.layer.zPosition = 0
        self.collectionView.layer.zPosition = 1
        self.view.insertSubview(self.finiteGradientView, belowSubview: self.collectionView)
    }

    private func layoutGradient() {
        guard self.experiment == .separated else { return }
        self.finiteGradientView.frame = GradientGeometry.frame(
            viewport: self.view.bounds,
            contentOffsetY: self.collectionView.contentOffset.y
        )
    }
}

extension HealthGradientViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        self.items.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "LabCell", for: indexPath)
        let item = self.items[indexPath.item]
        cell.backgroundColor = .clear
        cell.contentConfiguration = UIHostingConfiguration {
            LabItemView(item: item, experiment: self.experiment)
        }
        .margins(.all, 0)

        switch item {
        case .hero:
            cell.accessibilityIdentifier = "experiment.hero.\(self.experiment.rawValue)"
        case .specimen:
            cell.accessibilityIdentifier = "flattened.specimen"
        case .metrics:
            cell.accessibilityIdentifier = "recovered.parameters"
        default:
            cell.accessibilityIdentifier = nil
        }
        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let insets = (collectionViewLayout as? UICollectionViewFlowLayout)?.sectionInset ?? .zero
        return CGSize(
            width: collectionView.bounds.width - insets.left - insets.right,
            height: self.items[indexPath.item].height
        )
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.layoutGradient()
    }
}

private struct LabItemView: View {
    let item: LabItem
    let experiment: GradientExperiment

    @ViewBuilder
    var body: some View {
        switch self.item {
        case .hero:
            ExperimentHero(experiment: self.experiment)
        case .specimen:
            FlattenedSpecimen()
        case let .section(kicker, title):
            SectionHeading(kicker: kicker, title: title)
        case let .step(step):
            StepCard(step: step, accent: self.experiment.accent)
        case .layers:
            LayerDiagram(experiment: self.experiment)
        case .equation:
            EquationCard(experiment: self.experiment)
        case .metrics:
            MetricsCard()
        case .note:
            TakeawayCard(experiment: self.experiment)
        }
    }
}

private struct ExperimentHero: View {
    let experiment: GradientExperiment

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(self.experiment.badge, systemImage: self.experiment == .separated ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(self.experiment.accent)
                Spacer()
                Text(self.experiment == .separated ? "2 SOURCES" : "1 SOURCE")
                    .font(.caption2.monospaced().weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Text(self.experiment.heroTitle)
                .font(.title2.bold())
                .foregroundStyle(.white)

            Text(self.experiment.heroDetail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Label(self.experiment.result, systemImage: "arrow.down.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.82))
        }
        .labSurface(accent: self.experiment.accent, emphasized: true)
    }
}

private struct FlattenedSpecimen: View {
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            GradientSpecimenView()
            LinearGradient(colors: [.clear, .black.opacity(0.82)], startPoint: .top, endPoint: .bottom)

            VStack(alignment: .leading, spacing: 7) {
                Text("SCROLLING COLOR FIELD")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.72))
                Text("This field is part of the page")
                    .font(.title3.bold())
                Text("The next opaque card can replace it before the edge effect runs.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.78))
            }
            .padding(18)
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        }
    }
}

private struct SectionHeading: View {
    let kicker: String
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(self.kicker)
                .font(.caption2.weight(.bold))
                .foregroundStyle(.tertiary)
            Text(self.title)
                .font(.title3.bold())
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        .padding(.horizontal, 2)
    }
}

private struct StepCard: View {
    let step: LabStep
    let accent: Color

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Text(self.step.number)
                .font(.subheadline.monospaced().bold())
                .foregroundStyle(self.accent)
                .frame(width: 36, height: 36)
                .background(self.accent.opacity(0.14), in: Circle())

            VStack(alignment: .leading, spacing: 7) {
                Text(self.step.title)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(self.step.detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .labSurface(accent: self.accent)
    }
}

private struct LayerDiagram: View {
    let experiment: GradientExperiment

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(self.experiment == .separated ? "TWO INPUTS REACH THE EDGE" : "ONE FINISHED IMAGE REACHES THE EDGE")
                .font(.caption2.weight(.bold))
                .foregroundStyle(self.experiment.accent)

            LayerRow(
                icon: "text.below.photo",
                title: "Foreground",
                detail: "Opaque cards, text, and charts",
                tint: .orange
            )

            Connector(active: self.experiment == .separated)

            LayerRow(
                icon: "circle.hexagongrid.fill",
                title: "Color field",
                detail: self.experiment == .separated ? "Independent root sibling" : "Already covered inside the page",
                tint: .purple
            )

            Divider().overlay(.white.opacity(0.08))

            Label(
                self.experiment == .separated ? "Foreground softens; field remains" : "Opaque foreground has already won",
                systemImage: self.experiment == .separated ? "checkmark.seal.fill" : "exclamationmark.triangle.fill"
            )
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(self.experiment.accent)
        }
        .labSurface(accent: self.experiment.accent)
    }
}

private struct LayerRow: View {
    let icon: String
    let title: String
    let detail: String
    let tint: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: self.icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(self.tint)
                .frame(width: 40, height: 40)
                .background(self.tint.opacity(0.13), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(self.title)
                    .font(.headline)
                Text(self.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
    }
}

private struct Connector: View {
    let active: Bool

    var body: some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(self.active ? Color.cyan : Color.secondary.opacity(0.35))
                .frame(width: 2, height: 16)
                .padding(.leading, 19)
            Text(self.active ? "composited at the edge" : "flattened before the edge")
                .font(.caption2.monospaced())
                .foregroundStyle(.tertiary)
        }
    }
}

private struct EquationCard: View {
    let experiment: GradientExperiment

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("COMPOSITING ORDER")
                .font(.caption2.weight(.bold))
                .foregroundStyle(self.experiment.accent)

            Text(self.experiment == .separated
                 ? "soften(foreground)\n  over background"
                 : "edgeEffect(foreground\n  over background)")
                .font(.system(.body, design: .monospaced, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(.black.opacity(0.35), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            Text(self.experiment == .separated
                 ? "The background is still available when the foreground fades."
                 : "A blur cannot reconstruct pixels an opaque card already replaced.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .labSurface(accent: self.experiment.accent)
    }
}

private struct MetricsCard: View {
    private let metrics = [
        ("35%", "field height"),
        ("12°/s", "rotation"),
        ("4", "color inputs"),
        ("11", "fade samples"),
    ]

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(self.metrics, id: \.1) { value, label in
                VStack(alignment: .leading, spacing: 4) {
                    Text(value)
                        .font(.title2.monospacedDigit().bold())
                        .foregroundStyle(.white)
                    Text(label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 66, alignment: .leading)
                .padding(.horizontal, 14)
                .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .labSurface(accent: .purple)
    }
}

private struct TakeawayCard: View {
    let experiment: GradientExperiment

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "square.3.layers.3d.top.filled")
                .font(.title3)
                .foregroundStyle(self.experiment.accent)
                .frame(width: 42, height: 42)
                .background(self.experiment.accent.opacity(0.13), in: RoundedRectangle(cornerRadius: 13, style: .continuous))

            VStack(alignment: .leading, spacing: 7) {
                Text("Preserve the source planes")
                    .font(.headline)
                Text("The animated field can be beautiful, but the key is keeping it alive behind the edge treatment. Geometry creates the eventual fade to black.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .labSurface(accent: self.experiment.accent)
    }
}

private struct GradientSpecimenView: UIViewRepresentable {
    func makeUIView(context: Context) -> FiniteGradientView {
        FiniteGradientView()
    }

    func updateUIView(_ uiView: FiniteGradientView, context: Context) {}
}

private extension View {
    func labSurface(accent: Color, emphasized: Bool = false) -> some View {
        self
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(18)
            .background {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color(red: 0.075, green: 0.075, blue: 0.085))
                    .overlay(alignment: .topTrailing) {
                        if emphasized {
                            RadialGradient(
                                colors: [accent.opacity(0.15), .clear],
                                center: .topTrailing,
                                startRadius: 0,
                                endRadius: 180
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        }
                    }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(.white.opacity(0.085), lineWidth: 1)
            }
    }
}
