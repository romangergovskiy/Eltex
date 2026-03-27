import UIKit

final class ViewController: UIViewController {

    private let headerImageView = UIImageView()
    private let containerView = UIView()
    private let filterStack = UIStackView()
    private let runButton = UIButton(type: .system)
    private let botSwitch = UISwitch()

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let emptyStateLabel = UILabel()

    private var isFirstRun = true
    private var greetingText: String = ""
    private var trades: [TradeRecord] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateEmptyState()
    }
}

// MARK: - Setup
private extension ViewController {

    func setupUI() {
        [headerImageView, containerView, filterStack, runButton, botSwitch, tableView, emptyStateLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        view.backgroundColor = .darkGray

        setupHeader()
        setupContainer()
        setupFilter()
        setupRunButton()
        setupTableView()
        setupEmptyState()

        addSubviews()
        makeConstraints()
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
        filterStack.distribution = .equalSpacing

        let titleLabel = UILabel()
        titleLabel.text = "Торговый бот"
        titleLabel.textColor = .black
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)

        filterStack.addArrangedSubview(titleLabel)
        filterStack.addArrangedSubview(botSwitch)
        filterStack.addArrangedSubview(UIView())
    }

    func setupRunButton() {
        runButton.setTitle("Начать торговлю", for: .normal)
        runButton.setTitleColor(.black, for: .normal)
        runButton.backgroundColor = .systemBlue
        runButton.layer.cornerRadius = 12
        runButton.addTarget(self, action: #selector(runTapped), for: .touchUpInside)
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
    }

    func makeConstraints() {
        NSLayoutConstraint.activate([
            // Header
            headerImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            headerImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            headerImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerImageView.heightAnchor.constraint(equalToConstant: 160),

            // Container
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            containerView.topAnchor.constraint(equalTo: headerImageView.bottomAnchor, constant: 20),
            containerView.heightAnchor.constraint(equalToConstant: 180),

            // Filter stack
            filterStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 10),
            filterStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -10),
            filterStack.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            filterStack.heightAnchor.constraint(equalToConstant: 40),

            // Run button
            runButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            runButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            runButton.topAnchor.constraint(equalTo: filterStack.bottomAnchor, constant: 20),
            runButton.heightAnchor.constraint(equalToConstant: 50),

            // Table
            tableView.topAnchor.constraint(equalTo: containerView.bottomAnchor, constant: 20),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            // Empty state
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
        let trader = Trader(balance: 10000, currency: .usd)
        let bot = TradingBot(trader: trader)

        greetingText = bot.greeting()
        trades = bot.generateHistory(count: 40)

        isFirstRun = false
        updateEmptyState()
        tableView.reloadData()
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
