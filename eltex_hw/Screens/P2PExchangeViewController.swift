import UIKit
import OSLog

final class P2PExchangeViewController: UIViewController {
    weak var coordinator: P2PExchangeRouting?
    private let viewModel: P2PExchangeViewModel
    private var state: P2PExchangeViewState = .idle(P2PExchangeViewData(pairText: "USD-BTC", balancesText: "", offers: []))
    private var viewData = P2PExchangeViewData(pairText: "USD-BTC", balancesText: "", offers: [])
    private var lastShownErrorMessage: String?

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

    init(viewModel: P2PExchangeViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        AppLogger.p2p.info("P2PExchangeViewController did load")
        setupUI()
        setupNavigationBar()
        bindViewModel()
        viewModel.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        AppLogger.p2p.debug("P2PExchangeViewController will appear")
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        viewModel.viewWillAppear()
    }
}

private extension P2PExchangeViewController {
    func bindViewModel() {
        viewModel.onStateChange = { [weak self] newState in
            guard let self else { return }
            self.state = newState
            self.viewData = newState.viewData
            self.render(state: newState)
        }
        viewModel.onTradeSuccess = { [weak self] result in
            self?.showSuccessResult(result: result)
        }
    }

    func render(state: P2PExchangeViewState) {
        let data = state.viewData
        pairValueLabel.text = data.pairText
        balancesLabel.text = data.balancesText
        tableView.reloadData()
        let isEmpty = data.offers.isEmpty
        emptyStateLabel.isHidden = !isEmpty
        tableView.isHidden = isEmpty
        let isLoading = state.isLoading
        refreshButton.isEnabled = !isLoading
        pairContainerView.isUserInteractionEnabled = !isLoading
        if isLoading {
            loadingIndicator.startAnimating()
        } else {
            loadingIndicator.stopAnimating()
        }
        if case let .error(_, error) = state {
            let message = "\(error.title)-\(error.message)"
            if lastShownErrorMessage != message {
                lastShownErrorMessage = message
                showNetworkError(error)
            }
        } else {
            lastShownErrorMessage = nil
        }
    }

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

    func showNetworkError(_ error: NetworkServiceError) {
        AppLogger.p2p.error("P2P screen error alert shown. error=\(error.logCode, privacy: .public)")
        let alert = UIAlertController(title: error.title, message: error.message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ок", style: .default))
        present(alert, animated: true)
    }

    func showTradeInput(for offer: P2POffer) {
        let codes = viewModel.pairCodes()
        let message = String(
            format: "Курс %.6f %@ за 1 %@\nРезерв продавца: %.2f %@",
            offer.rate,
            codes.target,
            codes.source,
            offer.reserve,
            codes.target
        )
        let alert = UIAlertController(
            title: offer.sellerName,
            message: message,
            preferredStyle: .alert
        )
        alert.addTextField {
            $0.placeholder = "Сумма в \(codes.source)"
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
                AppLogger.p2p.error("Trade input validation failed. invalid amount=\(rawAmount, privacy: .public)")
                self.showPlainError("Введите корректную сумму.")
                return
            }
            AppLogger.p2p.info("Trade input accepted. amount=\(amount, privacy: .public)")
            self.viewModel.executeTrade(amount: amount, offer: offer)
        })
        present(alert, animated: true)
    }

    func showSuccessResult(result: WalletExchangeResult) {
        AppLogger.p2p.info("Trade success alert shown. spent=\(result.spent, privacy: .public), received=\(result.received, privacy: .public)")
        let codes = viewModel.pairCodes()
        let message = String(
            format: "Списано: %.2f %@\nПолучено: %.2f %@",
            result.spent,
            codes.source,
            result.received,
            codes.target
        )
        let alert = UIAlertController(title: "Обмен выполнен", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ок", style: .default))
        present(alert, animated: true)
    }

    func showPlainError(_ message: String) {
        AppLogger.p2p.error("Plain error alert shown. message=\(message, privacy: .public)")
        let alert = UIAlertController(title: "Ошибка", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ок", style: .default))
        present(alert, animated: true)
    }

    @objc func selectPairTapped() {
        AppLogger.p2p.info("Pair selection requested")
        let input = viewModel.pairSelectionInput()
        coordinator?.showP2PPairSelector(
            delegate: self,
            allAssets: input.allAssets,
            firstAsset: input.first,
            secondAsset: input.second,
            apiAssets: input.apiAssets
        )
    }

    @objc func refreshTapped() {
        AppLogger.p2p.info("Refresh button tapped")
        viewModel.refreshOffers()
    }

    @objc func openWalletTapped() {
        AppLogger.p2p.info("Open wallet tapped from P2P screen")
        coordinator?.showP2PWallet()
    }

    @objc func exchangeAmountChanged(_ textField: UITextField) {
        guard let text = textField.text else { return }
        textField.text = text
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "−", with: "")
    }
}

extension P2PExchangeViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewData.offers.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        viewData.offers.isEmpty ? nil : "Предложения продавцов"
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: P2POfferTableViewCell.reuseIdentifier,
            for: indexPath
        ) as? P2POfferTableViewCell else {
            return UITableViewCell()
        }
        let offer = viewData.offers[indexPath.row]
        let codes = viewModel.pairCodes()
        cell.configure(offer: offer, sourceCode: codes.source, targetCode: codes.target)
        cell.onDetailsTap = { [weak self] in
            guard let self else { return }
            let pairCodes = self.viewModel.pairCodes()
            self.coordinator?.showSellerInfo(offer: offer, sourceCode: pairCodes.source, targetCode: pairCodes.target)
        }
        return cell
    }
}

extension P2PExchangeViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let offer = viewData.offers[indexPath.row]
        showTradeInput(for: offer)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        202
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let header = view as? UITableViewHeaderFooterView else { return }
        header.textLabel?.textColor = UIColor.white.withAlphaComponent(0.9)
        header.contentView.backgroundColor = .clear
    }
}

extension P2PExchangeViewController: CurrencyPairsViewControllerDelegate {
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
    }
}

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
