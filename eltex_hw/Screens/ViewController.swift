import UIKit

final class ViewController: UIViewController {

    // MARK: - Properties

    private let headerImageView = UIImageView()
    private let containerView = UIView()
    private let filterStack = UIStackView()
    private let runButton = UIButton(type: .system)
    private let pairSelectionView = UIView()
    private let pairTitleLabel = UILabel()
    private let pairValueLabel = UILabel()
    private let pairHintLabel = UILabel()
    private let pairChevronImageView = UIImageView(image: UIImage(systemName: "chevron.right"))
    private let botSwitch = UISwitch()

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let emptyStateLabel = UILabel()

    private var isFirstRun = true
    private var greetingText = ""
    private var trades: [TradeRecord] = []
    private lazy var tradingBot = TradingBot(trader: Trader(balance: 10000, currency: .usd))

    private let allAssets = PairAssetFactory.makeList(minCount: 140)
    private let defaultFirstCode = "USD"
    private let defaultSecondCode = "BTC"
    private var firstAsset: PairAsset = PairAsset(code: "USD", category: .fiat)
    private var secondAsset: PairAsset = PairAsset(code: "BTC", category: .crypto)

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupInitialPair()
        setupUI()
        setupNavigationBar()
        setupGestures()
        updatePairText()
        updateEmptyState()
    }
}

private extension ViewController {

    // MARK: - Setup

    func setupInitialPair() {
        let fallback = allAssets.first ?? PairAsset(code: "USD", category: .fiat)
        firstAsset = allAssets.first(where: { $0.code == defaultFirstCode }) ?? fallback
        secondAsset = allAssets.first(where: { $0.code == defaultSecondCode }) ?? allAssets.first(where: { $0.code != firstAsset.code }) ?? fallback
    }

    func setupUI() {
        setupAutoresizingMasks()
        view.backgroundColor = UIColor(red: 0.06, green: 0.09, blue: 0.16, alpha: 1)

        setupHeader()
        setupContainer()
        setupFilter()
        setupRunButton()
        setupPairSelection()
        setupTableView()
        setupEmptyState()

        addSubviews()
        makeConstraints()
    }

    func setupAutoresizingMasks() {
        [headerImageView, containerView, filterStack, runButton, pairSelectionView, pairTitleLabel, pairValueLabel, pairHintLabel, pairChevronImageView, botSwitch, tableView, emptyStateLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
    }

    func setupNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 0.06, green: 0.09, blue: 0.16, alpha: 1)
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]

        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        navigationController?.navigationBar.tintColor = .systemBlue

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "trash"),
            style: .plain,
            target: self,
            action: #selector(resetTapped)
        )

        let randomButton = UIBarButtonItem(
            image: UIImage(systemName: "shuffle"),
            style: .plain,
            target: self,
            action: #selector(randomPairTapped)
        )

        let chartButton = UIBarButtonItem(
            image: UIImage(systemName: "chart.bar.xaxis"),
            style: .plain,
            target: self,
            action: #selector(openChartTapped)
        )

        navigationItem.rightBarButtonItems = [chartButton, randomButton]
    }

    func setupGestures() {
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeUp))
        swipeUp.direction = .up
        view.addGestureRecognizer(swipeUp)
    }

    func setupHeader() {
        headerImageView.contentMode = .scaleAspectFill
        headerImageView.clipsToBounds = true
        headerImageView.layer.cornerRadius = 18
        headerImageView.image = UIImage(named: "fordz")
    }

    func setupContainer() {
        containerView.backgroundColor = UIColor(red: 0.13, green: 0.18, blue: 0.29, alpha: 1)
        containerView.layer.cornerRadius = 18
    }

    func setupFilter() {
        filterStack.axis = .horizontal
        filterStack.spacing = 10
        filterStack.distribution = .fill
        filterStack.alignment = .center

        let titleLabel = UILabel()
        titleLabel.text = "Торговый бот"
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)

        filterStack.addArrangedSubview(titleLabel)
        filterStack.addArrangedSubview(UIView())
        filterStack.addArrangedSubview(botSwitch)
        botSwitch.onTintColor = .systemTeal
    }

    func setupRunButton() {
        runButton.setTitle("Начать торговлю", for: .normal)
        runButton.setTitleColor(.white, for: .normal)
        runButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        runButton.backgroundColor = UIColor(red: 0.19, green: 0.48, blue: 0.96, alpha: 1)
        runButton.layer.cornerRadius = 12
        runButton.addTarget(self, action: #selector(runTapped), for: .touchUpInside)
    }

    func setupPairSelection() {
        pairSelectionView.backgroundColor = UIColor(red: 0.22, green: 0.72, blue: 0.55, alpha: 1)
        pairSelectionView.layer.cornerRadius = 12
        pairSelectionView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(pairSelectionTapped)))

        pairTitleLabel.text = "Текущая валютная пара"
        pairTitleLabel.font = .systemFont(ofSize: 12, weight: .medium)
        pairTitleLabel.textColor = .white

        pairValueLabel.font = .systemFont(ofSize: 20, weight: .bold)
        pairValueLabel.textColor = .white

        pairHintLabel.text = "Нажмите, чтобы выбрать"
        pairHintLabel.font = .systemFont(ofSize: 12, weight: .regular)
        pairHintLabel.textColor = .white

        pairChevronImageView.tintColor = .white

        pairSelectionView.addSubview(pairTitleLabel)
        pairSelectionView.addSubview(pairValueLabel)
        pairSelectionView.addSubview(pairHintLabel)
        pairSelectionView.addSubview(pairChevronImageView)
    }

    func setupTableView() {
        tableView.register(
            TradeTableViewCell.self,
            forCellReuseIdentifier: TradeTableViewCell.reuseIdentifier
        )
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "GreetingCell")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.showsVerticalScrollIndicator = true
        tableView.sectionHeaderTopPadding = 8
    }

    func setupEmptyState() {
        emptyStateLabel.text = "Нет данных"
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.font = .systemFont(ofSize: 24, weight: .semibold)
        emptyStateLabel.textColor = .secondaryLabel
        emptyStateLabel.numberOfLines = 0
    }

    func addSubviews() {
        view.addSubview(headerImageView)
        view.addSubview(containerView)
        view.addSubview(tableView)
        view.addSubview(emptyStateLabel)

        containerView.addSubview(filterStack)
        containerView.addSubview(runButton)
        containerView.addSubview(pairSelectionView)
    }

    func makeConstraints() {
        NSLayoutConstraint.activate([
            headerImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            headerImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            headerImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerImageView.heightAnchor.constraint(equalToConstant: 160),

            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            containerView.topAnchor.constraint(equalTo: headerImageView.bottomAnchor, constant: 20),
            containerView.heightAnchor.constraint(equalToConstant: 260),

            filterStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 10),
            filterStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -10),
            filterStack.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            filterStack.heightAnchor.constraint(equalToConstant: 40),

            runButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            runButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            runButton.topAnchor.constraint(equalTo: filterStack.bottomAnchor, constant: 20),
            runButton.heightAnchor.constraint(equalToConstant: 50),

            pairSelectionView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            pairSelectionView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            pairSelectionView.topAnchor.constraint(equalTo: runButton.bottomAnchor, constant: 14),
            pairSelectionView.heightAnchor.constraint(equalToConstant: 82),

            pairTitleLabel.topAnchor.constraint(equalTo: pairSelectionView.topAnchor, constant: 10),
            pairTitleLabel.leadingAnchor.constraint(equalTo: pairSelectionView.leadingAnchor, constant: 12),
            pairTitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: pairChevronImageView.leadingAnchor, constant: -8),

            pairValueLabel.topAnchor.constraint(equalTo: pairTitleLabel.bottomAnchor, constant: 2),
            pairValueLabel.leadingAnchor.constraint(equalTo: pairSelectionView.leadingAnchor, constant: 12),
            pairValueLabel.trailingAnchor.constraint(lessThanOrEqualTo: pairChevronImageView.leadingAnchor, constant: -8),

            pairHintLabel.topAnchor.constraint(equalTo: pairValueLabel.bottomAnchor, constant: 2),
            pairHintLabel.leadingAnchor.constraint(equalTo: pairSelectionView.leadingAnchor, constant: 12),
            pairHintLabel.bottomAnchor.constraint(lessThanOrEqualTo: pairSelectionView.bottomAnchor, constant: -8),

            pairChevronImageView.trailingAnchor.constraint(equalTo: pairSelectionView.trailingAnchor, constant: -12),
            pairChevronImageView.centerYAnchor.constraint(equalTo: pairSelectionView.centerYAnchor),
            pairChevronImageView.widthAnchor.constraint(equalToConstant: 14),
            pairChevronImageView.heightAnchor.constraint(equalToConstant: 20),

            tableView.topAnchor.constraint(equalTo: containerView.bottomAnchor, constant: 20),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            emptyStateLabel.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: tableView.centerYAnchor),
            emptyStateLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            emptyStateLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20)
        ])
    }
}

private extension ViewController {

    // MARK: - Actions

    @objc func runTapped() {
        tradingBot.resetSession()
        greetingText = "\(tradingBot.greeting())\nПара: \(firstAsset.code)-\(secondAsset.code)"
        trades = tradingBot.generateHistory(count: 40)
        isFirstRun = false

        updateEmptyState()
        tableView.reloadData()
    }

    @objc func pairSelectionTapped() {
        let compactSelector = CurrencyPairsViewController(
            mode: .compact,
            allAssets: allAssets,
            firstAsset: firstAsset,
            secondAsset: secondAsset,
            selectedSide: .first
        )
        compactSelector.delegate = self

        let presentedNavigation = UINavigationController(rootViewController: compactSelector)
        presentedNavigation.modalPresentationStyle = .pageSheet
        if let sheet = presentedNavigation.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
        }
        present(presentedNavigation, animated: true)
    }

    @objc func resetTapped() {
        setupInitialPair()
        updatePairText()
        resetTradingState()
    }

    @objc func randomPairTapped() {
        guard allAssets.count > 1 else { return }
        let first = allAssets.randomElement() ?? allAssets[0]
        let others = allAssets.filter { $0.code != first.code }
        let second = others.randomElement() ?? first
        applyPairChange(first: first, second: second)
    }

    @objc func openChartTapped() {
        let chartsViewController = ChartsViewController()
        chartsViewController.title = "График"
        navigationController?.pushViewController(chartsViewController, animated: true)
    }

    @objc func handleSwipeUp() {
        openChartTapped()
    }

    func applyPairChange(first: PairAsset, second: PairAsset) {
        guard first.code != second.code else { return }

        let didChange = first.code != firstAsset.code || second.code != secondAsset.code
        firstAsset = first
        secondAsset = second
        updatePairText()

        if didChange {
            resetTradingState()
        }
    }

    func updatePairText() {
        pairValueLabel.text = "\(firstAsset.code)-\(secondAsset.code)"
    }

    func resetTradingState() {
        isFirstRun = true
        greetingText = ""
        trades = []
        botSwitch.setOn(false, animated: true)
        updateEmptyState()
        tableView.reloadData()
    }

    func updateEmptyState() {
        let shouldShowEmpty = isFirstRun || trades.isEmpty
        emptyStateLabel.isHidden = !shouldShowEmpty
        tableView.isHidden = shouldShowEmpty
    }
}

extension ViewController: UITableViewDataSource {
    // MARK: - UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return greetingText.isEmpty ? 0 : 1
        case 1:
            return trades.isEmpty ? 0 : trades.count
        default:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return greetingText.isEmpty ? nil : "Приветствие"
        case 1:
            return trades.isEmpty ? nil : "История сделок"
        default:
            return nil
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "GreetingCell", for: indexPath)
            cell.textLabel?.text = greetingText
            cell.textLabel?.numberOfLines = 0
            cell.textLabel?.font = .systemFont(ofSize: 16)
            cell.textLabel?.textAlignment = .center
            cell.backgroundColor = UIColor(red: 0.13, green: 0.18, blue: 0.29, alpha: 1)
            cell.textLabel?.textColor = .white
            cell.selectionStyle = .none
            return cell
        }

        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: TradeTableViewCell.reuseIdentifier,
            for: indexPath
        ) as? TradeTableViewCell else {
            return UITableViewCell()
        }

        cell.configure(with: trades[indexPath.row])
        return cell
    }
}

extension ViewController: UITableViewDelegate {
    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard indexPath.section == 1 else { return UITableView.automaticDimension }
        let trade = trades[indexPath.row]
        return trade.action == .ignore ? 76 : 122
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        indexPath.section == 0 ? 44 : 100
    }
}

extension ViewController: CurrencyPairsViewControllerDelegate {
    // MARK: - CurrencyPairsViewControllerDelegate

    func currencyPairsViewController(
        _ controller: CurrencyPairsViewController,
        didUpdateFirstAsset firstAsset: PairAsset,
        secondAsset: PairAsset
    ) {
        applyPairChange(first: firstAsset, second: secondAsset)
    }

    func currencyPairsViewControllerDidRequestFullList(
        _ controller: CurrencyPairsViewController,
        firstAsset: PairAsset,
        secondAsset: PairAsset,
        selectedSide: CurrencyPairsViewController.SelectionSide
    ) {
        dismiss(animated: true) { [weak self] in
            guard let self else { return }
            let fullSelector = CurrencyPairsViewController(
                mode: .full,
                allAssets: self.allAssets,
                firstAsset: firstAsset,
                secondAsset: secondAsset,
                selectedSide: selectedSide,
                startsWithFavoritesOnly: true
            )
            fullSelector.delegate = self
            self.navigationController?.pushViewController(fullSelector, animated: true)
        }
    }
}
