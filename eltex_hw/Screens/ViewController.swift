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
    private let botsCounterLabel = UILabel()

    private var isFirstRun = true
    private var statusText = ""
    private var dailyResults: [BotDayResult] = []
    private var bots: [TradingBot] = []
    private let wallet = Wallet(
        initialBalances: AppConfig.initialWalletBalances,
        autoCreditAmount: AppConfig.autoCreditAmount
    )
    private lazy var tradingEngine = TradingEngine(config: AppConfig.tradingConfig)

    private let allAssets = PairAssetFactory.makeList(minCount: 140)
    private let defaultFirstCode = "USD"
    private let defaultSecondCode = "BTC"
    private var firstAsset: PairAsset = PairAsset(code: "USD", category: .fiat)
    private var secondAsset: PairAsset = PairAsset(code: "BTC", category: .crypto)
    private var isCompactLayout: Bool {
        view.bounds.height <= 700
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupInitialPair()
        configureDefaultBotsForCurrentPair()
        setupUI()
        setupNavigationBar()
        setupGestures()
        updatePairText()
        updateBotsCounter()
        updateEmptyState()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let useLargeTitle = !isCompactLayout
        navigationController?.navigationBar.prefersLargeTitles = useLargeTitle
        navigationItem.largeTitleDisplayMode = useLargeTitle ? .always : .never
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
        [headerImageView, containerView, filterStack, runButton, pairSelectionView, pairTitleLabel, pairValueLabel, pairHintLabel, pairChevronImageView, botSwitch, tableView, emptyStateLabel, botsCounterLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
    }

    func setupNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 0.06, green: 0.09, blue: 0.16, alpha: 1)
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 20, weight: .semibold)
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 34, weight: .bold)
        ]

        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        navigationController?.navigationBar.tintColor = .systemBlue

        navigationItem.prompt = nil
        navigationItem.title = "Торговля"
        let iconConfig = UIImage.SymbolConfiguration(pointSize: 17, weight: .semibold)

        let resetButton = UIBarButtonItem(
            image: UIImage(systemName: "trash", withConfiguration: iconConfig),
            style: .plain,
            target: self,
            action: #selector(resetTapped)
        )

        let addBotButton = UIBarButtonItem(
            image: UIImage(systemName: "plus.circle", withConfiguration: iconConfig),
            style: .plain,
            target: self,
            action: #selector(addBotTapped)
        )

        let randomButton = UIBarButtonItem(
            image: UIImage(systemName: "shuffle", withConfiguration: iconConfig),
            style: .plain,
            target: self,
            action: #selector(randomPairTapped)
        )

        let chartButton = UIBarButtonItem(
            image: UIImage(systemName: "chart.bar.xaxis", withConfiguration: iconConfig),
            style: .plain,
            target: self,
            action: #selector(openChartTapped)
        )

        let walletButton = UIBarButtonItem(
            image: UIImage(systemName: "wallet.bifold", withConfiguration: iconConfig),
            style: .plain,
            target: self,
            action: #selector(openWalletTapped)
        )

        navigationItem.leftBarButtonItems = [resetButton, addBotButton]
        navigationItem.rightBarButtonItems = [walletButton, chartButton, randomButton]
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
        botSwitch.isOn = true
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

        botsCounterLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        botsCounterLabel.textColor = UIColor.white.withAlphaComponent(0.9)
        botsCounterLabel.textAlignment = .right

        pairSelectionView.addSubview(pairTitleLabel)
        pairSelectionView.addSubview(pairValueLabel)
        pairSelectionView.addSubview(pairHintLabel)
        pairSelectionView.addSubview(pairChevronImageView)
        pairSelectionView.addSubview(botsCounterLabel)
    }

    func setupTableView() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "StatusCell")
        tableView.register(
            TradeTableViewCell.self,
            forCellReuseIdentifier: TradeTableViewCell.reuseIdentifier
        )
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.sectionIndexColor = .white
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
        let headerHeight: CGFloat = isCompactLayout ? 120 : 160
        let containerHeight: CGFloat = isCompactLayout ? 236 : 260
        let topSpacingAfterHeader: CGFloat = isCompactLayout ? 12 : 20
        let topSpacingAfterContainer: CGFloat = isCompactLayout ? 12 : 20

        NSLayoutConstraint.activate([
            headerImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            headerImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            headerImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerImageView.heightAnchor.constraint(equalToConstant: headerHeight),

            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            containerView.topAnchor.constraint(equalTo: headerImageView.bottomAnchor, constant: topSpacingAfterHeader),
            containerView.heightAnchor.constraint(equalToConstant: containerHeight),

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

            botsCounterLabel.trailingAnchor.constraint(equalTo: pairChevronImageView.leadingAnchor, constant: -8),
            botsCounterLabel.centerYAnchor.constraint(equalTo: pairTitleLabel.centerYAnchor),
            botsCounterLabel.leadingAnchor.constraint(greaterThanOrEqualTo: pairTitleLabel.trailingAnchor, constant: 6),

            pairChevronImageView.trailingAnchor.constraint(equalTo: pairSelectionView.trailingAnchor, constant: -12),
            pairChevronImageView.centerYAnchor.constraint(equalTo: pairSelectionView.centerYAnchor),
            pairChevronImageView.widthAnchor.constraint(equalToConstant: 14),
            pairChevronImageView.heightAnchor.constraint(equalToConstant: 20),

            tableView.topAnchor.constraint(equalTo: containerView.bottomAnchor, constant: topSpacingAfterContainer),
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
        if bots.isEmpty {
            configureDefaultBotsForCurrentPair()
            updateBotsCounter()
        }

        guard botSwitch.isOn else {
            showError("Включите переключатель бота перед запуском.")
            return
        }

        runButton.isEnabled = false
        runButton.alpha = 0.65
        setControlsEnabled(false)
        statusText = "Выполняем расчеты... Ботов: \(bots.count), дней: \(AppConfig.numberOfDays), операций в день: \(AppConfig.minOperationsPerDay)-\(AppConfig.maxOperationsPerDay)"
        isFirstRun = false
        dailyResults = []
        tableView.reloadData()
        updateEmptyState()

        tradingEngine.run(
            bots: bots,
            wallet: wallet,
            progress: { [weak self] day, totalDays in
                guard let self else { return }
                self.statusText = "Выполняем расчеты... день \(day)/\(totalDays), ботов: \(self.bots.count), операций в день: \(AppConfig.minOperationsPerDay)-\(AppConfig.maxOperationsPerDay)"
                self.tableView.reloadSections(IndexSet(integer: 0), with: .none)
            },
            completion: { [weak self] results in
            guard let self else { return }
            self.dailyResults = results
            self.runButton.isEnabled = true
            self.runButton.alpha = 1.0
            self.setControlsEnabled(true)
            self.statusText = "Готово. Выполнено результатов: \(results.count)."
            self.updateEmptyState()
            self.tableView.reloadData()
        })
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
        bots = []
        wallet.reset(to: AppConfig.initialWalletBalances)
        updateBotsCounter()
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
        chartsViewController.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(chartsViewController, animated: true)
    }

    @objc func addBotTapped() {
        let alert = UIAlertController(
            title: "Новый бот",
            message: "Введите уникальное имя. Бот будет привязан к текущей паре \(firstAsset.code)-\(secondAsset.code).",
            preferredStyle: .alert
        )
        alert.addTextField {
            $0.placeholder = "Например: BotBtcMaster"
            $0.autocapitalizationType = .none
            $0.clearButtonMode = .whileEditing
        }

        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        alert.addAction(UIAlertAction(title: "Добавить", style: .default) { [weak self, weak alert] _ in
            guard let self else { return }
            let input = alert?.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !input.isEmpty else {
                self.showError("Имя бота не может быть пустым.")
                return
            }

            guard !self.bots.contains(where: { $0.setup.name.lowercased() == input.lowercased() }) else {
                self.showError("Бот с таким именем уже есть.")
                return
            }

            let setup = BotSetup(
                name: input,
                baseCurrency: self.firstAsset.code,
                quoteCurrency: self.secondAsset.code,
                baseCategory: self.firstAsset.category,
                quoteCategory: self.secondAsset.category
            )
            self.bots.append(TradingBot(setup: setup, wallet: self.wallet))
            self.updateBotsCounter()
            self.statusText = "Добавлен бот \(input) для пары \(setup.pairCode)."
            self.isFirstRun = false
            self.updateEmptyState()
            self.tableView.reloadData()
        })
        present(alert, animated: true)
    }

    @objc func openWalletTapped() {
        let walletController = WalletViewController(wallet: wallet)
        let navController = UINavigationController(rootViewController: walletController)
        navController.modalPresentationStyle = .pageSheet
        present(navController, animated: true)
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
            migrateSomeBotsToCurrentPair(count: 3)
            updateBotsCounter()
            resetTradingState()
        }
    }

    func updatePairText() {
        pairValueLabel.text = "\(firstAsset.code)-\(secondAsset.code)"
    }

    func updateBotsCounter() {
        botsCounterLabel.text = "Ботов: \(bots.count)"
    }

    func configureDefaultBotsForCurrentPair() {
        guard bots.isEmpty else { return }
        let pairShort = "\(firstAsset.code)\(secondAsset.code)"
        bots = (1...AppConfig.defaultBotsPerPair).map { index in
            let setup = BotSetup(
                name: "Bot\(pairShort)\(index)",
                baseCurrency: firstAsset.code,
                quoteCurrency: secondAsset.code,
                baseCategory: firstAsset.category,
                quoteCategory: secondAsset.category
            )
            return TradingBot(setup: setup, wallet: wallet)
        }
    }

    func migrateSomeBotsToCurrentPair(count: Int) {
        guard !bots.isEmpty else { return }

        let migrateCount = min(max(0, count), bots.count)
        guard migrateCount > 0 else { return }

        for index in 0..<migrateCount {
            let previous = bots[index]
            let updatedSetup = BotSetup(
                name: previous.setup.name,
                baseCurrency: firstAsset.code,
                quoteCurrency: secondAsset.code,
                baseCategory: firstAsset.category,
                quoteCategory: secondAsset.category
            )
            bots[index] = TradingBot(setup: updatedSetup, wallet: wallet)
        }
    }

    func resetTradingState() {
        isFirstRun = true
        statusText = ""
        dailyResults = []
        updateEmptyState()
        tableView.reloadData()
    }

    func updateEmptyState() {
        let shouldShowEmpty = isFirstRun && statusText.isEmpty && dailyResults.isEmpty
        emptyStateLabel.isHidden = !shouldShowEmpty
        tableView.isHidden = shouldShowEmpty
    }

    func showError(_ message: String) {
        let alert = UIAlertController(title: "Ошибка", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    func setControlsEnabled(_ enabled: Bool) {
        navigationItem.leftBarButtonItems?.forEach { $0.isEnabled = enabled }
        navigationItem.rightBarButtonItems?.forEach { $0.isEnabled = enabled }
        pairSelectionView.isUserInteractionEnabled = enabled
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
            return statusText.isEmpty ? 0 : 1
        case 1:
            return dailyResults.isEmpty ? 0 : dailyResults.count
        default:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return statusText.isEmpty ? nil : "Статус"
        case 1:
            return dailyResults.isEmpty ? nil : "Результаты по дням и ботам"
        default:
            return nil
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "StatusCell", for: indexPath)
            cell.textLabel?.text = statusText
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
        cell.configure(with: dailyResults[indexPath.row])
        return cell
    }
}

extension ViewController: UITableViewDelegate {
    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        indexPath.section == 0 ? 50 : 110
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let header = view as? UITableViewHeaderFooterView else { return }
        header.textLabel?.textColor = UIColor.white.withAlphaComponent(0.9)
        header.contentView.backgroundColor = .clear
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
            fullSelector.navigationItem.largeTitleDisplayMode = .never
            fullSelector.delegate = self
            self.navigationController?.pushViewController(fullSelector, animated: true)
        }
    }
}
