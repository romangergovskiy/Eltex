import UIKit

final class ChartsViewController: UIViewController {

    // MARK: - Properties

    private enum ChartMode {
        case candles
        case line
    }

    private let chartContainerView = UIView()
    private let interactionHintLabel = UILabel()
    private lazy var modeSegmentedControl: UISegmentedControl = {
        let control = UISegmentedControl(items: ["Свечной", "Линейный"])
        control.translatesAutoresizingMaskIntoConstraints = false
        control.selectedSegmentIndex = 0
        control.addTarget(self, action: #selector(modeChanged), for: .valueChanged)
        return control
    }()

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
    private let lineChartView = LineChartView()

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
        lineChartView.points = candles.map { LinePointData(price: $0.close, title: $0.timeTitle) }
        lineChartView.onPointSelected = { [weak self] index in
            guard let self else { return }
            guard self.candles.indices.contains(index) else { return }
            let candle = self.candles[index]
            self.showDetails(for: candle)
            self.recommendationLabel.text = String(format: "Выбрана точка: %.2f", candle.close)
        }
        setChartMode(.candles)

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
        setupChartContainer()
        setupCollectionView()
        setupLineChart()
        setupModeSegmentedControl()
        setupInteractionHintLabel()
        setupDetailsContainer()
        setupRecommendationContainer()
        addSubviews()
        makeConstraints()
    }

    func setupChartContainer() {
        chartContainerView.translatesAutoresizingMaskIntoConstraints = false
        chartContainerView.backgroundColor = UIColor(red: 0.13, green: 0.18, blue: 0.29, alpha: 1)
        chartContainerView.layer.borderWidth = 1
        chartContainerView.layer.borderColor = UIColor.white.withAlphaComponent(0.08).cgColor
        chartContainerView.layer.cornerRadius = 12
        chartContainerView.clipsToBounds = true
    }

    func setupCollectionView() {
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
    }

    func setupLineChart() {
        lineChartView.translatesAutoresizingMaskIntoConstraints = false
        lineChartView.backgroundColor = .clear
    }

    func setupModeSegmentedControl() {
        modeSegmentedControl.backgroundColor = UIColor(red: 0.18, green: 0.25, blue: 0.39, alpha: 1)
        modeSegmentedControl.selectedSegmentTintColor = UIColor(red: 0.29, green: 0.52, blue: 0.97, alpha: 1)
        modeSegmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .normal)
        modeSegmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
    }

    func setupInteractionHintLabel() {
        interactionHintLabel.translatesAutoresizingMaskIntoConstraints = false
        interactionHintLabel.font = .systemFont(ofSize: 13, weight: .medium)
        interactionHintLabel.textColor = UIColor.white.withAlphaComponent(0.75)
        interactionHintLabel.numberOfLines = 0
        interactionHintLabel.textAlignment = .left
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
        view.addSubview(modeSegmentedControl)
        view.addSubview(interactionHintLabel)
        view.addSubview(chartContainerView)
        chartContainerView.addSubview(collectionView)
        chartContainerView.addSubview(lineChartView)
        view.addSubview(detailsContainerView)
        view.addSubview(recommendationContainerView)
    }

    func makeConstraints() {
        NSLayoutConstraint.activate([
            modeSegmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            modeSegmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            modeSegmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            modeSegmentedControl.heightAnchor.constraint(equalToConstant: 34),

            interactionHintLabel.topAnchor.constraint(equalTo: modeSegmentedControl.bottomAnchor, constant: 10),
            interactionHintLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 18),
            interactionHintLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -18),

            chartContainerView.topAnchor.constraint(equalTo: interactionHintLabel.bottomAnchor, constant: 8),
            chartContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            chartContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            chartContainerView.heightAnchor.constraint(equalToConstant: 260),

            collectionView.topAnchor.constraint(equalTo: chartContainerView.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: chartContainerView.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: chartContainerView.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: chartContainerView.bottomAnchor),

            lineChartView.topAnchor.constraint(equalTo: chartContainerView.topAnchor),
            lineChartView.leadingAnchor.constraint(equalTo: chartContainerView.leadingAnchor),
            lineChartView.trailingAnchor.constraint(equalTo: chartContainerView.trailingAnchor),
            lineChartView.bottomAnchor.constraint(equalTo: chartContainerView.bottomAnchor),

            detailsContainerView.topAnchor.constraint(equalTo: chartContainerView.bottomAnchor, constant: 16),
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
        candles = (0..<28).map { index in
            let open = Double.random(in: 100...200)
            let close = open + Double.random(in: -25...25)
            let high = max(open, close) + Double.random(in: 2...12)
            let low = min(open, close) - Double.random(in: 2...12)
            let hour = 9 + index
            let hourTitle = String(format: "%02d:00", hour % 24)

            return CandleData(
                open: open,
                close: close,
                high: high,
                low: low,
                timeTitle: hourTitle,
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

    @objc func modeChanged() {
        let mode: ChartMode = modeSegmentedControl.selectedSegmentIndex == 0 ? .candles : .line
        setChartMode(mode)
    }

    private func setChartMode(_ mode: ChartMode) {
        collectionView.isHidden = mode != .candles
        lineChartView.isHidden = mode != .line
        interactionHintLabel.text = mode == .candles
            ? "Нажмите на свечу, чтобы увидеть значения."
            : "Нажмите на график, чтобы увидеть значение в точке."
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
