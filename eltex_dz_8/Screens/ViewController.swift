//
//  ViewController.swift
//  eltex_dz_8
//
//  Created by Роман Герговский on 03.04.2026.
//

import UIKit

final class ViewController: UIViewController {

    private let headerImageView = UIImageView()
    private let containerView = UIView()
    private let filterStack = UIStackView()
    private let runButton = UIButton(type: .system)
    private let pairsButton = UIButton(type: .system)
    private let botSwitch = UISwitch()

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let emptyStateLabel = UILabel()

    private var isFirstRun = true
    private var greetingText: String = ""
    private var trades: [TradeRecord] = []
    private lazy var tradingBot = TradingBot(trader: Trader(balance: 10000, currency: .usd))

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateEmptyState()
    }
}

// MARK: - Setup
private extension ViewController {

    func setupUI() {
        setupAutoresizingMasks()
        view.backgroundColor = UIColor(red: 0.06, green: 0.09, blue: 0.16, alpha: 1)

        setupHeader()
        setupContainer()
        setupFilter()
        setupRunButton()
        setupPairsButton()
        setupTableView()
        setupEmptyState()

        addSubviews()
        makeConstraints()
    }

    func setupAutoresizingMasks() {
        [headerImageView, containerView, filterStack, runButton, pairsButton, botSwitch, tableView, emptyStateLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
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
        filterStack.distribution = .equalSpacing

        let titleLabel = UILabel()
        titleLabel.text = "Торговый бот"
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)

        filterStack.addArrangedSubview(titleLabel)
        filterStack.addArrangedSubview(botSwitch)
        filterStack.addArrangedSubview(UIView())
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

    func setupPairsButton() {
        pairsButton.setTitle("Экран валютных пар", for: .normal)
        pairsButton.setTitleColor(.white, for: .normal)
        pairsButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        pairsButton.backgroundColor = UIColor(red: 0.22, green: 0.72, blue: 0.55, alpha: 1)
        pairsButton.layer.cornerRadius = 12
        pairsButton.addTarget(self, action: #selector(openPairsTapped), for: .touchUpInside)
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
        containerView.addSubview(pairsButton)
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
            containerView.heightAnchor.constraint(equalToConstant: 240),

            filterStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 10),
            filterStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -10),
            filterStack.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            filterStack.heightAnchor.constraint(equalToConstant: 40),

            runButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            runButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            runButton.topAnchor.constraint(equalTo: filterStack.bottomAnchor, constant: 20),
            runButton.heightAnchor.constraint(equalToConstant: 50),

            pairsButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            pairsButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            pairsButton.topAnchor.constraint(equalTo: runButton.bottomAnchor, constant: 14),
            pairsButton.heightAnchor.constraint(equalToConstant: 50),

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

// MARK: - Actions
private extension ViewController {

    @objc func runTapped() {
        tradingBot.resetSession()
        greetingText = tradingBot.greeting()
        trades = tradingBot.generateHistory(count: 40)

        isFirstRun = false
        updateEmptyState()
        tableView.reloadData()
    }

    @objc func openPairsTapped() {
        let vc = CurrencyPairsViewController(nibName: nil, bundle: nil)
        present(vc, animated: true)
    }

    func updateEmptyState() {
        let shouldShowEmpty = isFirstRun || trades.isEmpty
        emptyStateLabel.isHidden = !shouldShowEmpty
        tableView.isHidden = shouldShowEmpty
    }
}

// MARK: - UITableViewDataSource
extension ViewController: UITableViewDataSource {

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

// MARK: - UITableViewDelegate
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

