import UIKit

final class ViewController: UIViewController {

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

    private let allAssets = PairAssetFactory.makeList(minCount: 140)
    private let defaultFirstCode = "USD"
    private let defaultSecondCode = "BTC"
    private var firstAsset: PairAsset!
    private var secondAsset: PairAsset!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupInitialPair()
        setupUI()
        setupNavigationBar()
        updatePairText()
        updateEmptyState()
    }
}

private extension ViewController {

    func setupInitialPair() {
        let fallback = allAssets.first ?? PairAsset(code: "USD", category: .fiat)
        firstAsset = allAssets.first(where: { $0.code == defaultFirstCode }) ?? fallback
        secondAsset = allAssets.first(where: { $0.code == defaultSecondCode }) ?? allAssets.first(where: { $0.code != firstAsset.code }) ?? fallback
    }

    func setupUI() {
        [headerImageView, containerView, filterStack, runButton, pairSelectionView, pairTitleLabel, pairValueLabel, pairHintLabel, pairChevronImageView, botSwitch, tableView, emptyStateLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        view.backgroundColor = .darkGray

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

    func setupNavigationBar() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "trash"),
            style: .plain,
            target: self,
            action: #selector(resetTapped)
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "shuffle"),
            style: .plain,
            target: self,
            action: #selector(randomPairTapped)
        )
    }

    func setupHeader() {
        headerImageView.contentMode = .scaleAspectFill
        headerImageView.clipsToBounds = true
        headerImageView.layer.cornerRadius = 10
        headerImageView.image = UIImage(named: "fordz")
    }

    func setupContainer() {
        containerView.backgroundColor = UIColor(white: 0.95, alpha: 1)
        containerView.layer.cornerRadius = 10
    }

    func setupFilter() {
        filterStack.axis = .horizontal
        filterStack.spacing = 10
        filterStack.distribution = .fill
        filterStack.alignment = .center

        let titleLabel = UILabel()
        titleLabel.text = "Торговый бот"
        titleLabel.textColor = .black
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)

        filterStack.addArrangedSubview(titleLabel)
        filterStack.addArrangedSubview(UIView())
        filterStack.addArrangedSubview(botSwitch)
    }

    func setupRunButton() {
        runButton.setTitle("Начать торговлю", for: .normal)
        runButton.setTitleColor(.black, for: .normal)
        runButton.backgroundColor = .systemBlue
        runButton.layer.cornerRadius = 12
        runButton.addTarget(self, action: #selector(runTapped), for: .touchUpInside)
    }

    func setupPairSelection() {
        pairSelectionView.backgroundColor = .systemGreen
        pairSelectionView.layer.cornerRadius = 12
        pairSelectionView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(pairSelectionTapped)))

        pairTitleLabel.text = "Текущая валютная пара"
        pairTitleLabel.font = .systemFont(ofSize: 12, weight: .medium)
        pairTitleLabel.textColor = .black

        pairValueLabel.font = .systemFont(ofSize: 20, weight: .bold)
        pairValueLabel.textColor = .black

        pairHintLabel.text = "Нажмите, чтобы выбрать"
        pairHintLabel.font = .systemFont(ofSize: 12, weight: .regular)
        pairHintLabel.textColor = .darkGray

        pairChevronImageView.tintColor = .black

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
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.showsVerticalScrollIndicator = true
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

    @objc func runTapped() {
        let trader = Trader(balance: 10000, currency: .usd)
        let bot = TradingBot(trader: trader)

        greetingText = "\(bot.greeting())\nПара: \(firstAsset.code)-\(secondAsset.code)"
        trades = bot.generateHistory(count: 40)
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

    func numberOfSections(in tableView: UITableView) -> Int {
        2
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
            let cell = UITableViewCell(style: .default, reuseIdentifier: "GreetingCell")
            cell.textLabel?.text = greetingText
            cell.textLabel?.numberOfLines = 0
            cell.textLabel?.font = .systemFont(ofSize: 16)
            cell.textLabel?.textAlignment = .center
            cell.backgroundColor = .systemGray6
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
