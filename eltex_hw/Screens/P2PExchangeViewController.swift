import UIKit

final class P2PExchangeViewController: UIViewController {

    // MARK: - Properties

    private let wallet: Wallet
    private let networkService: NetworkService

    private let allAssets = PairAssetFactory.makeList(minCount: 140)
    private var apiAssets: [PairAsset] = []
    private var offers: [P2POffer] = []

    private var firstAsset = PairAsset(code: "USD", category: .fiat)
    private var secondAsset = PairAsset(code: "BTC", category: .crypto)

    private let pairContainerView = UIView()
    private let pairTitleLabel = UILabel()
    private let pairValueLabel = UILabel()
    private let pairHintLabel = UILabel()
    private let pairChevronImageView = UIImageView(image: UIImage(systemName: "chevron.right"))
    private let balancesLabel = UILabel()
    private let refreshButton = UIButton(type: .system)

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let emptyStateLabel = UILabel()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)

    // MARK: - Lifecycle

    init(wallet: Wallet, networkService: NetworkService = NetworkService()) {
        self.wallet = wallet
        self.networkService = networkService
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        updatePairText()
        updateBalances()
        loadAssetsAndOffers()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        updateBalances()
    }
}

// MARK: - Private

private extension P2PExchangeViewController {
    // MARK: Setup

    func setupUI() {
        view.backgroundColor = UIColor(red: 0.06, green: 0.09, blue: 0.16, alpha: 1)

        [pairContainerView, pairTitleLabel, pairValueLabel, pairHintLabel, pairChevronImageView, balancesLabel, refreshButton, tableView, emptyStateLabel, loadingIndicator].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        pairContainerView.backgroundColor = UIColor(red: 0.13, green: 0.18, blue: 0.29, alpha: 1)
        pairContainerView.layer.cornerRadius = 14
        pairContainerView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(selectPairTapped)))

        pairTitleLabel.text = "Текущая P2P пара"
        pairTitleLabel.font = .systemFont(ofSize: 12, weight: .medium)
        pairTitleLabel.textColor = .white

        pairValueLabel.font = .systemFont(ofSize: 22, weight: .bold)
        pairValueLabel.textColor = .white

        pairHintLabel.text = "Нажмите для смены валют"
        pairHintLabel.font = .systemFont(ofSize: 12, weight: .regular)
        pairHintLabel.textColor = UIColor.white.withAlphaComponent(0.9)

        pairChevronImageView.tintColor = .white

        balancesLabel.font = .systemFont(ofSize: 14, weight: .medium)
        balancesLabel.textColor = UIColor.white.withAlphaComponent(0.95)
        balancesLabel.numberOfLines = 0

        refreshButton.setTitle("Обновить предложения", for: .normal)
        refreshButton.setTitleColor(.white, for: .normal)
        refreshButton.backgroundColor = UIColor(red: 0.19, green: 0.48, blue: 0.96, alpha: 1)
        refreshButton.layer.cornerRadius = 12
        refreshButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        refreshButton.addTarget(self, action: #selector(refreshTapped), for: .touchUpInside)

        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.sectionHeaderTopPadding = 8
        tableView.register(P2POfferTableViewCell.self, forCellReuseIdentifier: P2POfferTableViewCell.reuseIdentifier)

        emptyStateLabel.text = "Список предложений пуст"
        emptyStateLabel.textColor = .secondaryLabel
        emptyStateLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.numberOfLines = 0
        emptyStateLabel.isHidden = true

        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.color = .white

        view.addSubview(pairContainerView)
        pairContainerView.addSubview(pairTitleLabel)
        pairContainerView.addSubview(pairValueLabel)
        pairContainerView.addSubview(pairHintLabel)
        pairContainerView.addSubview(pairChevronImageView)
        view.addSubview(balancesLabel)
        view.addSubview(refreshButton)
        view.addSubview(tableView)
        view.addSubview(emptyStateLabel)
        view.addSubview(loadingIndicator)

        NSLayoutConstraint.activate([
            pairContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            pairContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            pairContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            pairContainerView.heightAnchor.constraint(equalToConstant: 98),

            pairTitleLabel.leadingAnchor.constraint(equalTo: pairContainerView.leadingAnchor, constant: 12),
            pairTitleLabel.topAnchor.constraint(equalTo: pairContainerView.topAnchor, constant: 12),
            pairTitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: pairChevronImageView.leadingAnchor, constant: -8),

            pairValueLabel.leadingAnchor.constraint(equalTo: pairContainerView.leadingAnchor, constant: 12),
            pairValueLabel.topAnchor.constraint(equalTo: pairTitleLabel.bottomAnchor, constant: 3),
            pairValueLabel.trailingAnchor.constraint(lessThanOrEqualTo: pairChevronImageView.leadingAnchor, constant: -8),

            pairHintLabel.leadingAnchor.constraint(equalTo: pairContainerView.leadingAnchor, constant: 12),
            pairHintLabel.topAnchor.constraint(equalTo: pairValueLabel.bottomAnchor, constant: 3),
            pairHintLabel.trailingAnchor.constraint(lessThanOrEqualTo: pairChevronImageView.leadingAnchor, constant: -8),

            pairChevronImageView.trailingAnchor.constraint(equalTo: pairContainerView.trailingAnchor, constant: -12),
            pairChevronImageView.centerYAnchor.constraint(equalTo: pairContainerView.centerYAnchor),
            pairChevronImageView.widthAnchor.constraint(equalToConstant: 14),
            pairChevronImageView.heightAnchor.constraint(equalToConstant: 20),

            balancesLabel.topAnchor.constraint(equalTo: pairContainerView.bottomAnchor, constant: 12),
            balancesLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            balancesLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            refreshButton.topAnchor.constraint(equalTo: balancesLabel.bottomAnchor, constant: 12),
            refreshButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            refreshButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            refreshButton.heightAnchor.constraint(equalToConstant: 48),

            tableView.topAnchor.constraint(equalTo: refreshButton.bottomAnchor, constant: 12),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            emptyStateLabel.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: tableView.centerYAnchor),
            emptyStateLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            emptyStateLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    func setupNavigationBar() {
        title = "P2P обмен"

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

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "wallet.bifold"),
            style: .plain,
            target: self,
            action: #selector(openWalletTapped)
        )
    }

    // MARK: Data

    func loadAssetsAndOffers() {
        setLoading(true)
        networkService.loadAvailableAssets { [weak self] result in
            guard let self else { return }
            switch result {
            case let .success(assets):
                self.apiAssets = assets
                self.alignPairWithAvailableAssets()
                self.reloadOffers()
            case let .failure(error):
                self.setLoading(false)
                self.showNetworkError(error)
            }
        }
    }

    func alignPairWithAvailableAssets() {
        guard !apiAssets.isEmpty else { return }
        if !apiAssets.contains(where: { $0.code == firstAsset.code }) {
            firstAsset = apiAssets.first ?? firstAsset
        }
        if !apiAssets.contains(where: { $0.code == secondAsset.code }) || secondAsset.code == firstAsset.code {
            secondAsset = apiAssets.first(where: { $0.code != firstAsset.code }) ?? secondAsset
        }
        updatePairText()
        updateBalances()
    }

    func reloadOffers() {
        setLoading(true)
        networkService.loadOffers(from: firstAsset.code, to: secondAsset.code) { [weak self] result in
            guard let self else { return }
            self.setLoading(false)
            switch result {
            case let .success(offers):
                self.offers = offers
                self.updateEmptyState()
                self.tableView.reloadData()
            case let .failure(error):
                self.offers = []
                self.updateEmptyState()
                self.tableView.reloadData()
                self.showNetworkError(error)
            }
        }
    }

    func updatePairText() {
        pairValueLabel.text = "\(firstAsset.code)-\(secondAsset.code)"
    }

    func updateBalances() {
        let pairBalances = wallet.pairBalances(base: firstAsset.code, quote: secondAsset.code)
        let source = pairBalances[firstAsset.code, default: 0]
        let target = pairBalances[secondAsset.code, default: 0]
        balancesLabel.text = String(
            format: "Баланс: %@ %.2f\nБаланс: %@ %.2f",
            firstAsset.code,
            source,
            secondAsset.code,
            target
        )
    }

    func updateEmptyState() {
        let isEmpty = offers.isEmpty
        emptyStateLabel.isHidden = !isEmpty
        tableView.isHidden = isEmpty
    }

    func setLoading(_ loading: Bool) {
        refreshButton.isEnabled = !loading
        pairContainerView.isUserInteractionEnabled = !loading
        if loading {
            loadingIndicator.startAnimating()
        } else {
            loadingIndicator.stopAnimating()
        }
    }

    // MARK: Alerts

    func showNetworkError(_ error: NetworkServiceError) {
        let alert = UIAlertController(title: error.title, message: error.message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ок", style: .default))
        present(alert, animated: true)
    }

    func showTradeInput(for offer: P2POffer) {
        let message = String(
            format: "Курс %.6f %@ за 1 %@\nРезерв продавца: %.2f %@",
            offer.rate,
            secondAsset.code,
            firstAsset.code,
            offer.reserve,
            secondAsset.code
        )
        let alert = UIAlertController(
            title: offer.sellerName,
            message: message,
            preferredStyle: .alert
        )
        alert.addTextField {
            $0.placeholder = "Сумма в \(self.firstAsset.code)"
            $0.keyboardType = .decimalPad
            $0.delegate = self
            $0.addTarget(self, action: #selector(self.exchangeAmountChanged(_:)), for: .editingChanged)
        }
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        alert.addAction(UIAlertAction(title: "Выполнить", style: .default) { [weak self, weak alert] _ in
            guard let self else { return }
            let rawAmount = alert?.textFields?.first?.text ?? ""
            let normalizedAmount = rawAmount.replacingOccurrences(of: ",", with: ".")
            guard let amount = Double(normalizedAmount), amount > 0 else {
                self.showPlainError("Введите корректную сумму.")
                return
            }
            self.executeTrade(amount: amount, offer: offer)
        })
        present(alert, animated: true)
    }

    func executeTrade(amount: Double, offer: P2POffer) {
        setLoading(true)
        networkService.executeExchange(
            wallet: wallet,
            from: firstAsset.code,
            to: secondAsset.code,
            amount: amount,
            rate: offer.rate
        ) { [weak self] result in
            guard let self else { return }
            self.setLoading(false)
            switch result {
            case let .success(exchangeResult):
                self.updateBalances()
                self.showSuccessResult(result: exchangeResult)
            case let .failure(error):
                self.showNetworkError(error)
            }
        }
    }

    func showSuccessResult(result: WalletExchangeResult) {
        let message = String(
            format: "Списано: %.2f %@\nПолучено: %.2f %@",
            result.spent,
            firstAsset.code,
            result.received,
            secondAsset.code
        )
        let alert = UIAlertController(title: "Обмен выполнен", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ок", style: .default))
        present(alert, animated: true)
    }

    func showPlainError(_ message: String) {
        let alert = UIAlertController(title: "Ошибка", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ок", style: .default))
        present(alert, animated: true)
    }

    // MARK: Actions

    @objc func selectPairTapped() {
        let controller = CurrencyPairsViewController(
            mode: .full,
            allAssets: allAssets,
            firstAsset: firstAsset,
            secondAsset: secondAsset,
            selectedSide: .first,
            startsWithFavoritesOnly: false,
            apiAssets: apiAssets
        )
        controller.delegate = self
        navigationController?.pushViewController(controller, animated: true)
    }

    @objc func refreshTapped() {
        reloadOffers()
    }

    @objc func openWalletTapped() {
        let walletController = WalletViewController(wallet: wallet)
        let navController = UINavigationController(rootViewController: walletController)
        navController.modalPresentationStyle = .pageSheet
        present(navController, animated: true)
    }

    @objc func exchangeAmountChanged(_ textField: UITextField) {
        guard let text = textField.text else { return }
        textField.text = text
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "−", with: "")
    }
}

// MARK: - UITableViewDataSource

extension P2PExchangeViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        offers.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        offers.isEmpty ? nil : "Предложения продавцов"
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: P2POfferTableViewCell.reuseIdentifier,
            for: indexPath
        ) as? P2POfferTableViewCell else {
            return UITableViewCell()
        }
        let offer = offers[indexPath.row]
        cell.configure(offer: offer, sourceCode: firstAsset.code, targetCode: secondAsset.code)
        return cell
    }
}

// MARK: - UITableViewDelegate

extension P2PExchangeViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let offer = offers[indexPath.row]
        showTradeInput(for: offer)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        116
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let header = view as? UITableViewHeaderFooterView else { return }
        header.textLabel?.textColor = UIColor.white.withAlphaComponent(0.9)
        header.contentView.backgroundColor = .clear
    }
}

// MARK: - CurrencyPairsViewControllerDelegate

extension P2PExchangeViewController: CurrencyPairsViewControllerDelegate {
    func currencyPairsViewController(
        _ controller: CurrencyPairsViewController,
        didUpdateFirstAsset firstAsset: PairAsset,
        secondAsset: PairAsset
    ) {
        self.firstAsset = firstAsset
        self.secondAsset = secondAsset
        updatePairText()
        updateBalances()
        reloadOffers()
    }

    func currencyPairsViewControllerDidRequestFullList(
        _ controller: CurrencyPairsViewController,
        firstAsset: PairAsset,
        secondAsset: PairAsset,
        selectedSide: CurrencyPairsViewController.SelectionSide
    ) {
    }
}

// MARK: - UITextFieldDelegate

extension P2PExchangeViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string.isEmpty {
            return true
        }

        let allowedCharacterSet = CharacterSet(charactersIn: "0123456789.,")
        if string.rangeOfCharacter(from: allowedCharacterSet.inverted) != nil {
            return false
        }

        let currentText = textField.text ?? ""
        guard let textRange = Range(range, in: currentText) else {
            return false
        }
        let updatedText = currentText.replacingCharacters(in: textRange, with: string)

        let separatorCount = updatedText.filter { $0 == "." || $0 == "," }.count
        return separatorCount <= 1
    }
}
