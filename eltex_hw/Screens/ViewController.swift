import UIKit

final class ViewController: UIViewController {
    weak var coordinator: TradingBotRouting?
    private let viewModel: TradingBotViewModel
    private var state = TradingBotViewState(
        pairText: "USD-BTC",
        botsCountText: "Ботов: 0",
        statusText: "",
        dailyResults: [],
        isFirstRun: true,
        controlsEnabled: true
    )

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

    private var isCompactLayout: Bool {
        view.bounds.height <= 700
    }

    init(viewModel: TradingBotViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        setupGestures()
        bindViewModel()
        viewModel.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let useLargeTitle = !isCompactLayout
        navigationController?.navigationBar.prefersLargeTitles = useLargeTitle
        navigationItem.largeTitleDisplayMode = useLargeTitle ? .always : .never
    }
}

private extension ViewController {
    func bindViewModel() {
        viewModel.onStateChange = { [weak self] newState in
            guard let self else { return }
            self.state = newState
            self.render(state: newState)
        }
        viewModel.onError = { [weak self] message in
            self?.showError(message)
        }
    }

    func render(state: TradingBotViewState) {
        pairValueLabel.text = state.pairText
        botsCounterLabel.text = state.botsCountText
        tableView.reloadData()
        let shouldShowEmpty = state.isFirstRun && state.statusText.isEmpty && state.dailyResults.isEmpty
        emptyStateLabel.isHidden = !shouldShowEmpty
        tableView.isHidden = shouldShowEmpty
        runButton.isEnabled = state.controlsEnabled
        runButton.alpha = state.controlsEnabled ? 1.0 : 0.65
        setControlsEnabled(state.controlsEnabled)
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

        let heatmapButton = UIBarButtonItem(
            image: UIImage(systemName: "square.grid.3x3.fill", withConfiguration: iconConfig),
            style: .plain,
            target: self,
            action: #selector(openHeatmapTapped)
        )

        navigationItem.leftBarButtonItems = [resetButton, addBotButton]
        navigationItem.rightBarButtonItems = [walletButton, heatmapButton, chartButton, randomButton]
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
    @objc func runTapped() {
        viewModel.runTrading(isEnabled: botSwitch.isOn)
    }

    @objc func pairSelectionTapped() {
        let input = viewModel.pairSelectionInput()
        coordinator?.showCompactPairSelector(
            delegate: self,
            allAssets: input.allAssets,
            firstAsset: input.first,
            secondAsset: input.second
        )
    }

    @objc func resetTapped() {
        viewModel.reset()
    }

    @objc func randomPairTapped() {
        viewModel.randomPair()
    }

    @objc func openChartTapped() {
        coordinator?.showCharts()
    }

    @objc func addBotTapped() {
        let alert = UIAlertController(
            title: "Новый бот",
            message: "Введите уникальное имя. Бот будет привязан к текущей паре \(state.pairText).",
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
            let input = alert?.textFields?.first?.text ?? ""
            self.viewModel.addBot(name: input)
        })
        present(alert, animated: true)
    }

    @objc func openWalletTapped() {
        coordinator?.showWallet()
    }

    @objc func openHeatmapTapped() {
        coordinator?.showHeatmap()
    }

    @objc func handleSwipeUp() {
        openChartTapped()
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
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return state.statusText.isEmpty ? 0 : 1
        case 1:
            return state.dailyResults.isEmpty ? 0 : state.dailyResults.count
        default:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return state.statusText.isEmpty ? nil : "Статус"
        case 1:
            return state.dailyResults.isEmpty ? nil : "Результаты по дням и ботам"
        default:
            return nil
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "StatusCell", for: indexPath)
            cell.textLabel?.text = state.statusText
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
        cell.configure(with: state.dailyResults[indexPath.row])
        return cell
    }
}

extension ViewController: UITableViewDelegate {
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
    func currencyPairsViewController(
        _ controller: CurrencyPairsViewController,
        didUpdateFirstAsset firstAsset: PairAsset,
        secondAsset: PairAsset
    ) {
        viewModel.applyPair(first: firstAsset, second: secondAsset)
    }

    func currencyPairsViewControllerDidRequestFullList(
        _ controller: CurrencyPairsViewController,
        firstAsset: PairAsset,
        secondAsset: PairAsset,
        selectedSide: CurrencyPairsViewController.SelectionSide
    ) {
        dismiss(animated: true) { [weak self] in
            guard let self else { return }
            let allAssets = self.viewModel.pairSelectionInput().allAssets
            self.coordinator?.showFullPairSelector(
                delegate: self,
                allAssets: allAssets,
                firstAsset: firstAsset,
                secondAsset: secondAsset,
                selectedSide: selectedSide
            )
        }
    }
}
