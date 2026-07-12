import UIKit

@MainActor
final class HealthGradientViewController: UIViewController {
    private enum CompositionMode: String {
        case sourceSeparated = "Source separated"
        case flattened = "Flattened baseline"

        var explanation: String {
            switch self {
            case .sourceSeparated:
                "Gradient is a root sibling behind the transparent collection view"
            case .flattened:
                "Gradient is inside the scroll view and flattened with opaque cards"
            }
        }
    }

    private enum Item {
        case mode
        case heading(String)
        case card(symbol: String, tint: UIColor, title: String, detail: String, metric: String?)

        var height: CGFloat {
            switch self {
            case .mode: return 92
            case .heading: return 46
            case let .card(_, _, _, detail, metric):
                if metric != nil { return 176 }
                return detail.count > 90 ? 190 : 154
            }
        }
    }

    private var mode: CompositionMode = .sourceSeparated
    private let finiteGradientView = FiniteGradientView()
    private let flattenedBackgroundHost = UIView()
    private let collectionView: UICollectionView
    private let items: [Item] = [
        .mode,
        .card(
            symbol: "heart.text.square.fill",
            tint: .systemPink,
            title: "Gradient Architecture",
            detail: "A finite Metal color field lives behind this opaque card. Scroll slowly and watch the compact title region.",
            metric: nil
        ),
        .heading("Pinned"),
        .card(
            symbol: "flame.fill",
            tint: .systemOrange,
            title: "Steps",
            detail: "Today",
            metric: "8,421 steps"
        ),
        .card(
            symbol: "bed.double.fill",
            tint: .systemIndigo,
            title: "Sleep",
            detail: "Last night",
            metric: "7 hr 42 min"
        ),
        .heading("Trends"),
        .card(
            symbol: "figure.walk",
            tint: .systemOrange,
            title: "Walking + Running Distance",
            detail: "On average, your total distance increased over the last 5 weeks.",
            metric: "6.8 km average"
        ),
        .card(
            symbol: "figure.stairs",
            tint: .systemCyan,
            title: "Flights Climbed",
            detail: "Your daily average is trending upward this month.",
            metric: "18 floors"
        ),
        .heading("Highlights"),
        .card(
            symbol: "figure.run",
            tint: .systemGreen,
            title: "Workouts",
            detail: "You completed four workouts this week for a total of 3 hours and 12 minutes.",
            metric: "4 workouts"
        ),
        .card(
            symbol: "heart.fill",
            tint: .systemRed,
            title: "Cardio Fitness",
            detail: "Your cardio fitness has remained above average for the last 12 weeks.",
            metric: "Above average"
        ),
    ]

    init() {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 14
        layout.sectionInset = UIEdgeInsets(top: 12, left: 20, bottom: 120, right: 20)
        self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(nibName: nil, bundle: nil)
        if ProcessInfo.processInfo.arguments.contains("--flattened") {
            self.mode = .flattened
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Summary"
        self.view.backgroundColor = .black
        self.navigationItem.largeTitleDisplayMode = .always
        self.configureModeMenu()
        self.configureCollectionView()
        self.applyCompositionMode()
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
        self.collectionView.accessibilityIdentifier = "research.collection"
        self.collectionView.register(ResearchCell.self, forCellWithReuseIdentifier: ResearchCell.reuseIdentifier)
        self.view.addSubview(self.collectionView)
    }

    private func configureModeMenu() {
        let separated = UIAction(
            title: CompositionMode.sourceSeparated.rawValue,
            subtitle: "Reconstructed Health-style hierarchy",
            image: UIImage(systemName: "square.3.layers.3d")
        ) { [weak self] _ in
            self?.setMode(.sourceSeparated)
        }
        let flattened = UIAction(
            title: CompositionMode.flattened.rawValue,
            subtitle: "Control showing the common failure",
            image: UIImage(systemName: "square.stack.3d.down.right")
        ) { [weak self] _ in
            self?.setMode(.flattened)
        }
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "slider.horizontal.3"),
            menu: UIMenu(title: "Composition Mode", children: [separated, flattened])
        )
        self.navigationItem.rightBarButtonItem?.accessibilityIdentifier = "mode.menu"
    }

    private func setMode(_ mode: CompositionMode) {
        guard self.mode != mode else { return }
        self.mode = mode
        self.applyCompositionMode()
        self.collectionView.reloadItems(at: [IndexPath(item: 0, section: 0)])
        self.view.setNeedsLayout()
    }

    private func applyCompositionMode() {
        self.finiteGradientView.removeFromSuperview()
        self.collectionView.backgroundView = nil

        switch self.mode {
        case .sourceSeparated:
            self.finiteGradientView.layer.zPosition = -1
            self.view.insertSubview(self.finiteGradientView, at: 0)
        case .flattened:
            self.finiteGradientView.layer.zPosition = 0
            self.flattenedBackgroundHost.backgroundColor = .black
            self.flattenedBackgroundHost.addSubview(self.finiteGradientView)
            self.collectionView.backgroundView = self.flattenedBackgroundHost
        }
    }

    private func layoutGradient() {
        switch self.mode {
        case .sourceSeparated:
            self.finiteGradientView.frame = GradientGeometry.frame(
                viewport: self.view.bounds,
                contentOffsetY: self.collectionView.contentOffset.y
            )
        case .flattened:
            self.finiteGradientView.frame = GradientGeometry.frame(
                viewport: CGRect(origin: .zero, size: self.flattenedBackgroundHost.bounds.size),
                contentOffsetY: self.collectionView.contentOffset.y
            )
        }
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

        let item = self.items[indexPath.item]
        switch item {
        case .mode:
            cell.configureMode(title: self.mode.rawValue, detail: self.mode.explanation)
        case let .heading(title):
            cell.configureHeading(title)
        case let .card(symbol, tint, title, detail, metric):
            cell.configureCard(symbol: symbol, tint: tint, title: title, detail: detail, metric: metric)
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
        case mode
        case heading
        case card
    }

    static let reuseIdentifier = "ResearchCell"

    private let cardBackground = UIView()
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let detailLabel = UILabel()
    private let metricLabel = UILabel()
    private let badgeLabel = UILabel()
    private var style: Style = .card

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.configureViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.cardBackground.isHidden = false
        self.iconView.isHidden = false
        self.detailLabel.isHidden = false
        self.metricLabel.isHidden = false
        self.badgeLabel.isHidden = true
        self.style = .card
        self.titleLabel.font = .preferredFont(forTextStyle: .headline)
        self.titleLabel.textColor = .label
        self.titleLabel.numberOfLines = 1
        self.accessibilityIdentifier = nil
    }

    private func configureViews() {
        self.cardBackground.backgroundColor = UIColor(white: 0.105, alpha: 1)
        self.cardBackground.layer.cornerRadius = 24
        self.cardBackground.layer.cornerCurve = .continuous
        self.contentView.addSubview(self.cardBackground)

        self.iconView.contentMode = .scaleAspectFit
        self.cardBackground.addSubview(self.iconView)

        self.titleLabel.font = .preferredFont(forTextStyle: .headline)
        self.cardBackground.addSubview(self.titleLabel)

        self.detailLabel.font = .preferredFont(forTextStyle: .body)
        self.detailLabel.textColor = .secondaryLabel
        self.detailLabel.numberOfLines = 0
        self.cardBackground.addSubview(self.detailLabel)

        self.metricLabel.font = .systemFont(ofSize: 30, weight: .semibold)
        self.metricLabel.textColor = .label
        self.cardBackground.addSubview(self.metricLabel)

        self.badgeLabel.font = .systemFont(ofSize: 12, weight: .bold)
        self.badgeLabel.textAlignment = .center
        self.badgeLabel.textColor = .white
        self.badgeLabel.backgroundColor = UIColor.white.withAlphaComponent(0.16)
        self.badgeLabel.layer.cornerRadius = 13
        self.badgeLabel.layer.cornerCurve = .continuous
        self.badgeLabel.clipsToBounds = true
        self.cardBackground.addSubview(self.badgeLabel)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.cardBackground.frame = self.contentView.bounds
        let inset: CGFloat = 20
        switch self.style {
        case .mode:
            self.badgeLabel.frame = CGRect(x: inset, y: 14, width: 170, height: 26)
            self.titleLabel.frame = CGRect(x: inset, y: 45, width: self.bounds.width - 2 * inset, height: 24)
            self.detailLabel.frame = CGRect(x: inset, y: 68, width: self.bounds.width - 2 * inset, height: 18)
        case .heading:
            self.titleLabel.frame = CGRect(x: 0, y: 8, width: self.bounds.width, height: 34)
        case .card:
            self.iconView.frame = CGRect(x: inset, y: 20, width: 25, height: 25)
            self.titleLabel.frame = CGRect(x: 56, y: 18, width: self.bounds.width - 76, height: 29)
            self.detailLabel.frame = CGRect(x: inset, y: 58, width: self.bounds.width - 2 * inset, height: 64)
            self.metricLabel.frame = CGRect(x: inset, y: self.bounds.height - 54, width: self.bounds.width - 2 * inset, height: 40)
        }
    }

    func configureMode(title: String, detail: String) {
        self.prepareForReuse()
        self.style = .mode
        self.cardBackground.backgroundColor = UIColor.black.withAlphaComponent(0.34)
        self.iconView.isHidden = true
        self.metricLabel.isHidden = true
        self.badgeLabel.isHidden = false
        self.badgeLabel.text = title.uppercased()
        self.titleLabel.text = "Composition experiment"
        self.detailLabel.text = detail
        self.detailLabel.font = .preferredFont(forTextStyle: .caption1)
        self.accessibilityIdentifier = "mode.card"
    }

    func configureHeading(_ title: String) {
        self.prepareForReuse()
        self.style = .heading
        self.cardBackground.backgroundColor = .clear
        self.iconView.isHidden = true
        self.detailLabel.isHidden = true
        self.metricLabel.isHidden = true
        self.titleLabel.text = title
        self.titleLabel.font = .preferredFont(forTextStyle: .title2)
        self.titleLabel.textColor = .label
    }

    func configureCard(symbol: String, tint: UIColor, title: String, detail: String, metric: String?) {
        self.prepareForReuse()
        self.style = .card
        self.cardBackground.backgroundColor = UIColor(white: 0.105, alpha: 1)
        self.iconView.image = UIImage(systemName: symbol)
        self.iconView.tintColor = tint
        self.titleLabel.text = title
        self.titleLabel.textColor = tint
        self.detailLabel.text = detail
        self.metricLabel.text = metric
        self.metricLabel.isHidden = metric == nil
        self.accessibilityLabel = [title, detail, metric].compactMap { $0 }.joined(separator: ", ")
    }
}
