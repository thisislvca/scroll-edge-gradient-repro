import UIKit

private struct ResearchStory {
    let eyebrow: String
    let title: String
    let detail: String
    let symbol: String
    let tint: UIColor
}

enum GradientExperiment: Int {
    case separated
    case onePass

    var navigationTitle: String {
        switch self {
        case .separated: "Color Under Glass"
        case .onePass: "One-pass Composite"
        }
    }

    var tabTitle: String {
        switch self {
        case .separated: "Separated"
        case .onePass: "One-pass"
        }
    }

    var tabImage: String {
        switch self {
        case .separated: "square.3.layers.3d"
        case .onePass: "square.stack.3d.down.right"
        }
    }

    var heroEyebrow: String {
        switch self {
        case .separated: "LIVE RECONSTRUCTION"
        case .onePass: "CONTROL EXPERIMENT"
        }
    }

    var heroTitle: String {
        switch self {
        case .separated: "Color survives glass."
        case .onePass: "Color gets buried."
        }
    }

    var heroDetail: String {
        switch self {
        case .separated:
            "An animated field remains behind opaque content, so the compact title can reveal its real colors."
        case .onePass:
            "The same field lives inside scrolling content. Once an opaque card reaches the edge, its dark pixels win."
        }
    }

    var badge: String {
        switch self {
        case .separated: "TWO SOURCES"
        case .onePass: "ONE SOURCE"
        }
    }
}

@MainActor
final class HealthGradientViewController: UIViewController {
    private enum Item {
        case hero
        case specimen
        case section(kicker: String, title: String)
        case story(ResearchStory)
        case equation(label: String, expression: String, detail: String)
        case parameters

        var height: CGFloat {
            switch self {
            case .hero: return 258
            case .specimen: return 250
            case .section: return 74
            case let .story(story): return story.detail.count > 120 ? 224 : 196
            case .equation: return 212
            case .parameters: return 228
            }
        }
    }

    private let experiment: GradientExperiment
    private let finiteGradientView = FiniteGradientView()
    private let collectionView: UICollectionView

    private var items: [Item] {
        let shared: [Item] = [
            .section(kicker: "THE QUESTION", title: "Why color stays visible"),
            .story(ResearchStory(
                eyebrow: "NOT A TINTED BAR",
                title: "Opaque cards erase what sits behind them.",
                detail: "A normal blur receives the already-composited page. If a card is opaque, its dark surface has replaced the gradient pixels before the edge effect starts.",
                symbol: "rectangle.on.rectangle.slash",
                tint: .systemOrange
            )),
            .equation(
                label: "THE FAILED MENTAL MODEL",
                expression: "edgeEffect(foreground over background)",
                detail: "Blurring that finished image can spread a card, but it cannot recover color that the card already covered."
            ),
            .section(kicker: "THE RECONSTRUCTION", title: "Keep two images alive"),
            .story(ResearchStory(
                eyebrow: "BACKGROUND SOURCE",
                title: "A finite animated color field.",
                detail: "The Metal field is a root sibling behind the scroll view. It translates upward one-for-one with scrolling, then its soft bottom edge reveals black.",
                symbol: "sparkles.rectangle.stack",
                tint: .systemPurple
            )),
            .equation(
                label: "THE COMPOSITING ORDER",
                expression: "soften(foreground)  over  background",
                detail: "Only the scrolling foreground is attenuated near the top. The color source is still available behind it."
            ),
            .section(kicker: "RECOVERED VALUES", title: "Small numbers, visible behavior"),
            .parameters,
            .section(kicker: "TRY THE EVIDENCE", title: "Scroll, then switch tabs"),
            .story(ResearchStory(
                eyebrow: "WHAT TO WATCH",
                title: "Follow one color through the title region.",
                detail: "On Separated, purple and blue retain their horizontal positions while the card softens. On One-pass, the same card turns the header into a neutral dark blur.",
                symbol: "eye.fill",
                tint: .systemTeal
            )),
            .story(ResearchStory(
                eyebrow: "CLEAN-ROOM NOTE",
                title: "Behavior reconstructed, shader approximated.",
                detail: "The hierarchy, geometry, timing, and fade are derived from observable implementation details. This project uses public APIs and a fresh Metal shader.",
                symbol: "checkmark.seal.fill",
                tint: .systemGreen
            )),
        ]

        switch self.experiment {
        case .separated:
            return [.hero] + shared
        case .onePass:
            return [.hero, .specimen] + shared
        }
    }

    init(experiment: GradientExperiment) {
        self.experiment = experiment
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 14
        layout.sectionInset = UIEdgeInsets(top: 12, left: 20, bottom: 120, right: 20)
        self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = self.experiment.navigationTitle
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
        self.collectionView.register(ResearchCell.self, forCellWithReuseIdentifier: ResearchCell.reuseIdentifier)
        self.view.addSubview(self.collectionView)
    }

    private func installExperimentComposition() {
        guard self.experiment == .separated else { return }
        self.finiteGradientView.layer.zPosition = -1
        self.view.insertSubview(self.finiteGradientView, at: 0)
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
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: ResearchCell.reuseIdentifier,
            for: indexPath
        ) as? ResearchCell else {
            return UICollectionViewCell()
        }

        switch self.items[indexPath.item] {
        case .hero:
            cell.configureHero(experiment: self.experiment)
        case .specimen:
            cell.configureSpecimen()
        case let .section(kicker, title):
            cell.configureSection(kicker: kicker, title: title)
        case let .story(story):
            cell.configureStory(story)
        case let .equation(label, expression, detail):
            cell.configureEquation(label: label, expression: expression, detail: detail)
        case .parameters:
            cell.configureParameters()
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

@MainActor
private final class ResearchCell: UICollectionViewCell {
    private enum Style {
        case hero, specimen, section, story, equation, parameters
    }

    static let reuseIdentifier = "ResearchCell"

    private let cardBackground = UIView()
    private let gradientSpecimen = FiniteGradientView()
    private let eyebrowLabel = UILabel()
    private let titleLabel = UILabel()
    private let detailLabel = UILabel()
    private let iconView = UIImageView()
    private let badgeLabel = UILabel()
    private let codeBackground = UIView()
    private let codeLabel = UILabel()
    private let accentLine = UIView()
    private var style: Style = .story

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.configureViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.style = .story
        self.cardBackground.isHidden = false
        self.gradientSpecimen.isHidden = true
        self.eyebrowLabel.isHidden = false
        self.titleLabel.isHidden = false
        self.detailLabel.isHidden = false
        self.iconView.isHidden = false
        self.badgeLabel.isHidden = true
        self.codeBackground.isHidden = true
        self.accentLine.isHidden = false
        self.cardBackground.backgroundColor = UIColor(white: 0.105, alpha: 0.96)
        self.cardBackground.layer.borderWidth = 1
        self.cardBackground.layer.borderColor = UIColor.white.withAlphaComponent(0.07).cgColor
        self.titleLabel.textColor = .label
        self.titleLabel.font = .systemFont(ofSize: 22, weight: .semibold)
        self.detailLabel.textColor = .secondaryLabel
        self.detailLabel.font = .preferredFont(forTextStyle: .body)
        self.detailLabel.numberOfLines = 0
        self.codeLabel.text = nil
        self.accessibilityIdentifier = nil
    }

    private func configureViews() {
        self.cardBackground.layer.cornerRadius = 26
        self.cardBackground.layer.cornerCurve = .continuous
        self.cardBackground.clipsToBounds = true
        self.contentView.addSubview(self.cardBackground)

        self.gradientSpecimen.layer.cornerRadius = 26
        self.gradientSpecimen.layer.cornerCurve = .continuous
        self.gradientSpecimen.clipsToBounds = true
        self.cardBackground.insertSubview(self.gradientSpecimen, at: 0)

        self.accentLine.layer.cornerRadius = 2
        self.cardBackground.addSubview(self.accentLine)

        self.eyebrowLabel.font = .systemFont(ofSize: 11, weight: .bold)
        self.eyebrowLabel.textColor = .secondaryLabel
        self.eyebrowLabel.adjustsFontForContentSizeCategory = true
        self.cardBackground.addSubview(self.eyebrowLabel)

        self.titleLabel.numberOfLines = 0
        self.titleLabel.lineBreakMode = .byWordWrapping
        self.titleLabel.adjustsFontForContentSizeCategory = true
        self.cardBackground.addSubview(self.titleLabel)

        self.detailLabel.adjustsFontForContentSizeCategory = true
        self.cardBackground.addSubview(self.detailLabel)

        self.iconView.contentMode = .scaleAspectFit
        self.cardBackground.addSubview(self.iconView)

        self.badgeLabel.font = .systemFont(ofSize: 11, weight: .bold)
        self.badgeLabel.textAlignment = .center
        self.badgeLabel.textColor = .white
        self.badgeLabel.backgroundColor = UIColor.white.withAlphaComponent(0.16)
        self.badgeLabel.layer.cornerRadius = 13
        self.badgeLabel.layer.cornerCurve = .continuous
        self.badgeLabel.clipsToBounds = true
        self.cardBackground.addSubview(self.badgeLabel)

        self.codeBackground.backgroundColor = UIColor.black.withAlphaComponent(0.32)
        self.codeBackground.layer.cornerRadius = 14
        self.codeBackground.layer.cornerCurve = .continuous
        self.cardBackground.addSubview(self.codeBackground)

        self.codeLabel.font = .monospacedSystemFont(ofSize: 13, weight: .medium)
        self.codeLabel.textColor = UIColor(red: 0.76, green: 0.84, blue: 1, alpha: 1)
        self.codeLabel.numberOfLines = 0
        self.codeBackground.addSubview(self.codeLabel)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.cardBackground.frame = self.contentView.bounds
        self.gradientSpecimen.frame = self.cardBackground.bounds
        let inset: CGFloat = 20
        let width = self.bounds.width - 2 * inset

        switch self.style {
        case .hero:
            self.accentLine.frame = CGRect(x: inset, y: 20, width: 42, height: 4)
            self.eyebrowLabel.frame = CGRect(x: inset, y: 34, width: width - 120, height: 18)
            self.badgeLabel.frame = CGRect(x: self.bounds.width - 112, y: 28, width: 92, height: 26)
            self.titleLabel.frame = CGRect(x: inset, y: 64, width: width, height: 64)
            self.detailLabel.frame = CGRect(x: inset, y: 134, width: width - 10, height: 92)
        case .specimen:
            self.accentLine.frame = CGRect(x: inset, y: 20, width: 42, height: 4)
            self.eyebrowLabel.frame = CGRect(x: inset, y: 34, width: width, height: 18)
            self.titleLabel.frame = CGRect(x: inset, y: 64, width: width - 40, height: 32)
            self.detailLabel.frame = CGRect(x: inset, y: 103, width: width - 26, height: 58)
            self.codeBackground.frame = CGRect(x: inset, y: self.bounds.height - 64, width: width, height: 44)
            self.codeLabel.frame = self.codeBackground.bounds.insetBy(dx: 12, dy: 7)
        case .section:
            self.eyebrowLabel.frame = CGRect(x: 2, y: 8, width: width, height: 16)
            self.titleLabel.frame = CGRect(x: 0, y: 27, width: self.bounds.width, height: 40)
        case .story:
            self.accentLine.frame = CGRect(x: inset, y: 20, width: 34, height: 4)
            self.eyebrowLabel.frame = CGRect(x: inset, y: 34, width: width - 58, height: 18)
            self.iconView.frame = CGRect(x: self.bounds.width - 48, y: 22, width: 26, height: 26)
            self.titleLabel.frame = CGRect(x: inset, y: 62, width: width, height: 52)
            self.detailLabel.frame = CGRect(x: inset, y: 120, width: width, height: self.bounds.height - 136)
        case .equation:
            self.accentLine.frame = CGRect(x: inset, y: 20, width: 34, height: 4)
            self.eyebrowLabel.frame = CGRect(x: inset, y: 34, width: width, height: 18)
            self.codeBackground.frame = CGRect(x: inset, y: 61, width: width, height: 52)
            self.codeLabel.frame = self.codeBackground.bounds.insetBy(dx: 12, dy: 8)
            self.detailLabel.frame = CGRect(x: inset, y: 128, width: width, height: 62)
        case .parameters:
            self.accentLine.frame = CGRect(x: inset, y: 20, width: 34, height: 4)
            self.eyebrowLabel.frame = CGRect(x: inset, y: 34, width: width, height: 18)
            self.titleLabel.frame = CGRect(x: inset, y: 61, width: width, height: 30)
            self.codeBackground.frame = CGRect(x: inset, y: 104, width: width, height: 102)
            self.codeLabel.frame = self.codeBackground.bounds.insetBy(dx: 14, dy: 10)
        }
    }

    func configureHero(experiment: GradientExperiment) {
        self.prepareForReuse()
        self.style = .hero
        self.cardBackground.backgroundColor = UIColor.black.withAlphaComponent(experiment == .separated ? 0.26 : 0.86)
        self.cardBackground.layer.borderColor = UIColor.white.withAlphaComponent(0.12).cgColor
        self.accentLine.backgroundColor = experiment == .separated ? .systemCyan : .systemOrange
        self.eyebrowLabel.text = experiment.heroEyebrow
        self.titleLabel.text = experiment.heroTitle
        self.titleLabel.font = .systemFont(ofSize: 30, weight: .bold)
        self.titleLabel.numberOfLines = 2
        self.detailLabel.text = experiment.heroDetail
        self.badgeLabel.isHidden = false
        self.badgeLabel.text = experiment.badge
        self.accessibilityIdentifier = "experiment.hero.\(experiment.rawValue)"
    }

    func configureSpecimen() {
        self.prepareForReuse()
        self.style = .specimen
        self.gradientSpecimen.isHidden = false
        self.cardBackground.backgroundColor = .clear
        self.cardBackground.layer.borderColor = UIColor.white.withAlphaComponent(0.15).cgColor
        self.accentLine.backgroundColor = .white
        self.eyebrowLabel.text = "SCROLLING COLOR FIELD"
        self.eyebrowLabel.textColor = UIColor.white.withAlphaComponent(0.75)
        self.titleLabel.text = "The field is now part of the page."
        self.titleLabel.textColor = .white
        self.titleLabel.font = .systemFont(ofSize: 23, weight: .bold)
        self.titleLabel.numberOfLines = 2
        self.detailLabel.text = "Scroll until the next opaque card occupies the top edge. The color cannot remain available there."
        self.detailLabel.textColor = UIColor.white.withAlphaComponent(0.86)
        self.codeBackground.isHidden = false
        self.codeLabel.text = "scrolling field + opaque card = flattened pixels"
        self.accessibilityIdentifier = "one-pass.specimen"
    }

    func configureSection(kicker: String, title: String) {
        self.prepareForReuse()
        self.style = .section
        self.cardBackground.backgroundColor = .clear
        self.cardBackground.layer.borderWidth = 0
        self.accentLine.isHidden = true
        self.iconView.isHidden = true
        self.detailLabel.isHidden = true
        self.eyebrowLabel.text = kicker
        self.eyebrowLabel.textColor = .tertiaryLabel
        self.titleLabel.text = title
        self.titleLabel.font = .systemFont(ofSize: 25, weight: .bold)
        self.titleLabel.numberOfLines = 1
    }

    func configureStory(_ story: ResearchStory) {
        self.prepareForReuse()
        self.style = .story
        self.accentLine.backgroundColor = story.tint
        self.eyebrowLabel.text = story.eyebrow
        self.titleLabel.text = story.title
        self.titleLabel.numberOfLines = 2
        self.detailLabel.text = story.detail
        self.iconView.image = UIImage(systemName: story.symbol)
        self.iconView.tintColor = story.tint
        self.accessibilityLabel = "\(story.title), \(story.detail)"
    }

    func configureEquation(label: String, expression: String, detail: String) {
        self.prepareForReuse()
        self.style = .equation
        self.accentLine.backgroundColor = .systemPurple
        self.iconView.isHidden = true
        self.eyebrowLabel.text = label
        self.codeBackground.isHidden = false
        self.codeLabel.text = expression
        self.detailLabel.text = detail
        self.accessibilityLabel = "\(label), \(expression), \(detail)"
    }

    func configureParameters() {
        self.prepareForReuse()
        self.style = .parameters
        self.accentLine.backgroundColor = .systemCyan
        self.iconView.isHidden = true
        self.eyebrowLabel.text = "OBSERVED IN THE SYSTEM APP"
        self.titleLabel.text = "The field has a real footprint."
        self.codeBackground.isHidden = false
        self.codeLabel.text = "height     0.35 × viewport\norigin     −max(scrollY, 0)\nrotation   12° / second\nfade       smoothstep × 11 samples"
        self.accessibilityIdentifier = "recovered.parameters"
    }
}
