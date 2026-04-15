import UIKit

final class ChartsViewController: UIViewController {

    // MARK: - Properties

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 10
        layout.sectionInset = UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = UIColor(white: 0.95, alpha: 1)
        collectionView.layer.cornerRadius = 12
        collectionView.showsHorizontalScrollIndicator = true
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(CandleCollectionViewCell.self, forCellWithReuseIdentifier: CandleCollectionViewCell.reuseIdentifier)
        return collectionView
    }()

    private let detailsContainerView = UIView()
    private let recommendationContainerView = UIView()

    private let openLabel = UILabel()
    private let closeLabel = UILabel()
    private let highLabel = UILabel()
    private let lowLabel = UILabel()
    private let recommendationLabel = UILabel()

    private var candles: [CandleData] = []

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.06, green: 0.09, blue: 0.16, alpha: 1)
        setupNavigationAppearance()
        setupUI()
        generateCandles()
        collectionView.reloadData()

        if let firstCandle = candles.first {
            showDetails(for: firstCandle)
        }
    }
}

private extension ChartsViewController {

    // MARK: - Setup

    func setupNavigationAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 0.06, green: 0.09, blue: 0.16, alpha: 1)
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]

        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        navigationController?.navigationBar.tintColor = .systemBlue
    }

    func setupUI() {
        setupCollectionView()
        setupDetailsContainer()
        setupRecommendationContainer()
        addSubviews()
        makeConstraints()
    }

    func setupCollectionView() {
        collectionView.backgroundColor = UIColor(red: 0.13, green: 0.18, blue: 0.29, alpha: 1)
        collectionView.layer.borderWidth = 1
        collectionView.layer.borderColor = UIColor.white.withAlphaComponent(0.08).cgColor
        collectionView.showsHorizontalScrollIndicator = false
    }

    func setupDetailsContainer() {
        detailsContainerView.translatesAutoresizingMaskIntoConstraints = false
        detailsContainerView.backgroundColor = UIColor(red: 0.13, green: 0.18, blue: 0.29, alpha: 1)
        detailsContainerView.layer.cornerRadius = 12
        detailsContainerView.layer.borderWidth = 1
        detailsContainerView.layer.borderColor = UIColor.white.withAlphaComponent(0.08).cgColor

        [openLabel, closeLabel, highLabel, lowLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.font = .systemFont(ofSize: 16, weight: .medium)
            $0.textColor = .white
            detailsContainerView.addSubview($0)
        }
    }

    func setupRecommendationContainer() {
        recommendationContainerView.translatesAutoresizingMaskIntoConstraints = false
        recommendationContainerView.backgroundColor = UIColor(red: 0.13, green: 0.18, blue: 0.29, alpha: 1)
        recommendationContainerView.layer.cornerRadius = 12
        recommendationContainerView.layer.borderWidth = 1
        recommendationContainerView.layer.borderColor = UIColor.white.withAlphaComponent(0.08).cgColor

        recommendationLabel.translatesAutoresizingMaskIntoConstraints = false
        recommendationLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        recommendationLabel.textColor = .white
        recommendationLabel.numberOfLines = 0
        recommendationLabel.text = "Рекомендации: —"
        recommendationContainerView.addSubview(recommendationLabel)
    }

    // MARK: - Layout

    func addSubviews() {
        view.addSubview(collectionView)
        view.addSubview(detailsContainerView)
        view.addSubview(recommendationContainerView)
    }

    func makeConstraints() {
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            collectionView.heightAnchor.constraint(equalToConstant: 260),

            detailsContainerView.topAnchor.constraint(equalTo: collectionView.bottomAnchor, constant: 16),
            detailsContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            detailsContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            detailsContainerView.heightAnchor.constraint(equalToConstant: 140),

            openLabel.topAnchor.constraint(equalTo: detailsContainerView.topAnchor, constant: 12),
            openLabel.leadingAnchor.constraint(equalTo: detailsContainerView.leadingAnchor, constant: 12),
            openLabel.trailingAnchor.constraint(equalTo: detailsContainerView.trailingAnchor, constant: -12),

            closeLabel.topAnchor.constraint(equalTo: openLabel.bottomAnchor, constant: 8),
            closeLabel.leadingAnchor.constraint(equalTo: openLabel.leadingAnchor),
            closeLabel.trailingAnchor.constraint(equalTo: openLabel.trailingAnchor),

            highLabel.topAnchor.constraint(equalTo: closeLabel.bottomAnchor, constant: 8),
            highLabel.leadingAnchor.constraint(equalTo: openLabel.leadingAnchor),
            highLabel.trailingAnchor.constraint(equalTo: openLabel.trailingAnchor),

            lowLabel.topAnchor.constraint(equalTo: highLabel.bottomAnchor, constant: 8),
            lowLabel.leadingAnchor.constraint(equalTo: openLabel.leadingAnchor),
            lowLabel.trailingAnchor.constraint(equalTo: openLabel.trailingAnchor),

            recommendationContainerView.topAnchor.constraint(equalTo: detailsContainerView.bottomAnchor, constant: 16),
            recommendationContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            recommendationContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            recommendationContainerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 70),

            recommendationLabel.topAnchor.constraint(equalTo: recommendationContainerView.topAnchor, constant: 12),
            recommendationLabel.bottomAnchor.constraint(equalTo: recommendationContainerView.bottomAnchor, constant: -12),
            recommendationLabel.leadingAnchor.constraint(equalTo: recommendationContainerView.leadingAnchor, constant: 12),
            recommendationLabel.trailingAnchor.constraint(equalTo: recommendationContainerView.trailingAnchor, constant: -12)
        ])
    }

    // MARK: - Data

    func generateCandles() {
        candles = (0..<28).map { _ in
            let open = Double.random(in: 100...200)
            let close = open + Double.random(in: -25...25)
            let high = max(open, close) + Double.random(in: 2...12)
            let low = min(open, close) - Double.random(in: 2...12)

            return CandleData(
                open: open,
                close: close,
                high: high,
                low: low,
                bodyHeight: CGFloat.random(in: 50...120),
                bodyTop: CGFloat.random(in: 40...100),
                topTailExtra: CGFloat.random(in: 8...28),
                bottomTailExtra: CGFloat.random(in: 8...28)
            )
        }
    }

    // MARK: - Presentation

    func showDetails(for candle: CandleData) {
        openLabel.text = String(format: "Открытие: %.2f", candle.open)
        closeLabel.text = String(format: "Закрытие: %.2f", candle.close)
        highLabel.text = String(format: "Максимум: %.2f", candle.high)
        lowLabel.text = String(format: "Минимум: %.2f", candle.low)
    }

    func showRecommendation(for candle: CandleData) {
        let value: String
        let delta = candle.close - candle.open
        if abs(delta) < 1.0 {
            value = "ждать"
        } else if delta > 0 {
            value = "покупать"
        } else {
            value = "продавать"
        }

        recommendationLabel.text = "Рекомендации: \(value)"
    }
}

private struct CandleData {
    let open: Double
    let close: Double
    let high: Double
    let low: Double

    let bodyHeight: CGFloat
    let bodyTop: CGFloat
    let topTailExtra: CGFloat
    let bottomTailExtra: CGFloat

    var isGrowing: Bool {
        close >= open
    }
}

private final class CandleView: UIView {
    // MARK: - Properties

    private let bodyView = UIView()
    private let tailView = UIView()

    private var bodyTopConstraint: NSLayoutConstraint?
    private var bodyHeightConstraint: NSLayoutConstraint?
    private var tailTopConstraint: NSLayoutConstraint?
    private var tailBottomConstraint: NSLayoutConstraint?

    var onTap: (() -> Void)?
    var onLongPress: (() -> Void)?

    // MARK: - Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    // MARK: - Setup

    private func setupView() {
        backgroundColor = .clear
        translatesAutoresizingMaskIntoConstraints = false

        bodyView.translatesAutoresizingMaskIntoConstraints = false
        tailView.translatesAutoresizingMaskIntoConstraints = false
        bodyView.layer.cornerRadius = 6
        tailView.layer.cornerRadius = 1.5

        addSubview(tailView)
        addSubview(bodyView)

        bodyTopConstraint = bodyView.topAnchor.constraint(equalTo: topAnchor, constant: 60)
        bodyHeightConstraint = bodyView.heightAnchor.constraint(equalToConstant: 70)
        tailTopConstraint = tailView.topAnchor.constraint(equalTo: topAnchor, constant: 45)
        tailBottomConstraint = tailView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -45)

        NSLayoutConstraint.activate([
            bodyView.centerXAnchor.constraint(equalTo: centerXAnchor),
            bodyView.widthAnchor.constraint(equalToConstant: 30),
            bodyTopConstraint,
            bodyHeightConstraint,

            tailView.centerXAnchor.constraint(equalTo: centerXAnchor),
            tailView.widthAnchor.constraint(equalToConstant: 3),
            tailTopConstraint,
            tailBottomConstraint
        ].compactMap { $0 })

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        addGestureRecognizer(longPress)
    }

    // MARK: - Configure

    func configure(with candle: CandleData) {
        let candleColor: UIColor = candle.isGrowing ? .systemGreen : .systemRed
        bodyView.backgroundColor = candleColor
        tailView.backgroundColor = candleColor

        let bodyBottom = candle.bodyTop + candle.bodyHeight
        bodyTopConstraint?.constant = candle.bodyTop
        bodyHeightConstraint?.constant = candle.bodyHeight
        tailTopConstraint?.constant = max(8, candle.bodyTop - candle.topTailExtra)
        tailBottomConstraint?.constant = -max(8, 220 - bodyBottom + candle.bottomTailExtra)
    }

    // MARK: - Actions

    @objc func handleTap() {
        onTap?()
    }

    @objc func handleLongPress(_ recognizer: UILongPressGestureRecognizer) {
        guard recognizer.state == .began else { return }
        onLongPress?()
    }
}

private final class CandleCollectionViewCell: UICollectionViewCell {
    // MARK: - Properties

    static let reuseIdentifier = "CandleCollectionViewCell"

    private let candleView = CandleView()

    // MARK: - Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(candleView)

        NSLayoutConstraint.activate([
            candleView.topAnchor.constraint(equalTo: contentView.topAnchor),
            candleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            candleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            candleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configure

    func configure(
        candle: CandleData,
        onTap: @escaping () -> Void,
        onLongPress: @escaping () -> Void
    ) {
        candleView.configure(with: candle)
        candleView.onTap = onTap
        candleView.onLongPress = onLongPress
    }
}

extension ChartsViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    // MARK: - UICollectionViewDataSource

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        candles.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: CandleCollectionViewCell.reuseIdentifier,
            for: indexPath
        ) as? CandleCollectionViewCell else {
            return UICollectionViewCell()
        }

        let candle = candles[indexPath.item]
        cell.configure(
            candle: candle,
            onTap: { [weak self] in
                self?.showDetails(for: candle)
            },
            onLongPress: { [weak self] in
                self?.showRecommendation(for: candle)
            }
        )
        return cell
    }

    // MARK: - UICollectionViewDelegateFlowLayout

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        CGSize(width: 42, height: 220)
    }
}
