import UIKit

final class WalletViewController: UIViewController {

    private enum Section: Int, CaseIterable {
        case balances
        case credit

        var title: String {
            switch self {
            case .balances:
                return "Балансы"
            case .credit:
                return "Credit / Debt"
            }
        }
    }

    private let wallet: Wallet
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var balances: [(currency: String, amount: Double)] = []
    private var credit: [(currency: String, amount: Double)] = []

    init(wallet: Wallet) {
        self.wallet = wallet
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadSnapshot()
    }
}

private extension WalletViewController {
    func setupUI() {
        title = "Кошелек"
        view.backgroundColor = UIColor(red: 0.06, green: 0.09, blue: 0.16, alpha: 1)
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 0.06, green: 0.09, blue: 0.16, alpha: 1)
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.sectionHeaderTopPadding = 8
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "WalletCell")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "CreditCell")
        view.addSubview(tableView)

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeTapped)
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "arrow.clockwise"),
            style: .plain,
            target: self,
            action: #selector(refreshTapped)
        )
        navigationController?.navigationBar.tintColor = .systemBlue

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    func loadSnapshot() {
        let snapshot = wallet.fullSnapshot()
        balances = snapshot.balances
            .map { ($0.key, $0.value) }
            .sorted { $0.currency < $1.currency }
        credit = snapshot.credit
            .map { ($0.key, $0.value) }
            .sorted { $0.currency < $1.currency }
        tableView.reloadData()
    }

    @objc func closeTapped() {
        dismiss(animated: true)
    }

    @objc func refreshTapped() {
        loadSnapshot()
    }
}

extension WalletViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        Section.allCases.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sectionKind = Section(rawValue: section) else { return 0 }
        switch sectionKind {
        case .balances:
            return balances.count
        case .credit:
            return max(credit.count, 1)
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        Section(rawValue: section)?.title
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let sectionKind = Section(rawValue: indexPath.section) else {
            return UITableViewCell()
        }

        let reuseIdentifier = sectionKind == .balances ? "WalletCell" : "CreditCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
        cell.backgroundColor = UIColor(red: 0.13, green: 0.18, blue: 0.29, alpha: 1)
        cell.contentView.backgroundColor = UIColor(red: 0.13, green: 0.18, blue: 0.29, alpha: 1)
        cell.textLabel?.textColor = .white
        cell.textLabel?.numberOfLines = 1
        cell.selectionStyle = .none

        switch sectionKind {
        case .balances:
            let item = balances[indexPath.row]
            cell.textLabel?.text = "\(item.currency): \(item.amount.formatted)"
        case .credit:
            if credit.isEmpty {
                cell.textLabel?.text = "Кредит не использовался"
            } else {
                let item = credit[indexPath.row]
                cell.textLabel?.text = "\(item.currency): \(item.amount.formatted)"
            }
        }
        return cell
    }
}

extension WalletViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let header = view as? UITableViewHeaderFooterView else { return }
        header.textLabel?.textColor = UIColor.white.withAlphaComponent(0.9)
        header.contentView.backgroundColor = .clear
    }
}
