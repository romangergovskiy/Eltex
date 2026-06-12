import UIKit

final class SettingsViewController: UIViewController {

    // MARK: - Properties

    var onSignOutConfirmed: (() -> Void)?

    private let authManager: AuthSessionManager
    private let autoLoginLabel = UILabel()
    private let autoLoginSwitch = UISwitch()
    private let networkModeLabel = UILabel()
    private let networkModeControl = UISegmentedControl(items: ["Classic", "Combine"])
    private let signOutButton = UIButton(type: .system)
    private let rowContainer = UIView()
    private let networkRowContainer = UIView()
    private let screenColor = UIColor(red: 0.06, green: 0.09, blue: 0.16, alpha: 1)
    private let cardColor = UIColor(red: 0.13, green: 0.18, blue: 0.29, alpha: 1)

    init(authManager: AuthSessionManager) {
        self.authManager = authManager
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateState()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigationBar()
    }
}

private extension SettingsViewController {

    // MARK: - Setup

    func setupUI() {
        view.backgroundColor = screenColor

        [rowContainer, autoLoginLabel, autoLoginSwitch, networkRowContainer, networkModeLabel, networkModeControl, signOutButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        rowContainer.backgroundColor = cardColor
        rowContainer.layer.cornerRadius = 12
        networkRowContainer.backgroundColor = cardColor
        networkRowContainer.layer.cornerRadius = 12

        autoLoginLabel.text = "Автовход"
        autoLoginLabel.font = .systemFont(ofSize: 17, weight: .regular)
        autoLoginLabel.textColor = .white

        autoLoginSwitch.onTintColor = .systemTeal
        autoLoginSwitch.addTarget(self, action: #selector(autoLoginChanged), for: .valueChanged)

        networkModeLabel.text = "Режим сети"
        networkModeLabel.font = .systemFont(ofSize: 17, weight: .regular)
        networkModeLabel.textColor = .white

        networkModeControl.selectedSegmentIndex = AppConfig.isNetworkWithCombine ? 1 : 0
        networkModeControl.selectedSegmentTintColor = .systemBlue
        networkModeControl.backgroundColor = cardColor
        networkModeControl.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .normal)
        networkModeControl.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        networkModeControl.addTarget(self, action: #selector(networkModeChanged), for: .valueChanged)

        signOutButton.setTitle("Выйти", for: .normal)
        signOutButton.setTitleColor(.white, for: .normal)
        signOutButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        signOutButton.backgroundColor = .systemRed
        signOutButton.layer.cornerRadius = 12
        signOutButton.addTarget(self, action: #selector(signOutTapped), for: .touchUpInside)

        view.addSubview(rowContainer)
        rowContainer.addSubview(autoLoginLabel)
        rowContainer.addSubview(autoLoginSwitch)
        view.addSubview(networkRowContainer)
        networkRowContainer.addSubview(networkModeLabel)
        networkRowContainer.addSubview(networkModeControl)
        view.addSubview(signOutButton)

        NSLayoutConstraint.activate([
            rowContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            rowContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            rowContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            rowContainer.heightAnchor.constraint(equalToConstant: 56),

            autoLoginLabel.leadingAnchor.constraint(equalTo: rowContainer.leadingAnchor, constant: 16),
            autoLoginLabel.centerYAnchor.constraint(equalTo: rowContainer.centerYAnchor),
            autoLoginLabel.trailingAnchor.constraint(lessThanOrEqualTo: autoLoginSwitch.leadingAnchor, constant: -8),

            autoLoginSwitch.trailingAnchor.constraint(equalTo: rowContainer.trailingAnchor, constant: -16),
            autoLoginSwitch.centerYAnchor.constraint(equalTo: rowContainer.centerYAnchor),

            networkRowContainer.topAnchor.constraint(equalTo: rowContainer.bottomAnchor, constant: 12),
            networkRowContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            networkRowContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            networkRowContainer.heightAnchor.constraint(equalToConstant: 96),

            networkModeLabel.topAnchor.constraint(equalTo: networkRowContainer.topAnchor, constant: 14),
            networkModeLabel.leadingAnchor.constraint(equalTo: networkRowContainer.leadingAnchor, constant: 16),
            networkModeLabel.trailingAnchor.constraint(equalTo: networkRowContainer.trailingAnchor, constant: -16),

            networkModeControl.topAnchor.constraint(equalTo: networkModeLabel.bottomAnchor, constant: 10),
            networkModeControl.leadingAnchor.constraint(equalTo: networkRowContainer.leadingAnchor, constant: 16),
            networkModeControl.trailingAnchor.constraint(equalTo: networkRowContainer.trailingAnchor, constant: -16),
            networkModeControl.bottomAnchor.constraint(equalTo: networkRowContainer.bottomAnchor, constant: -14),

            signOutButton.topAnchor.constraint(equalTo: networkRowContainer.bottomAnchor, constant: 24),
            signOutButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            signOutButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            signOutButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    func setupNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = screenColor
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
    }

    func updateState() {
        autoLoginSwitch.isOn = authManager.autoLoginEnabled
        networkModeControl.selectedSegmentIndex = AppConfig.isNetworkWithCombine ? 1 : 0
    }

    @objc func autoLoginChanged() {
        authManager.autoLoginEnabled = autoLoginSwitch.isOn
    }

    @objc func networkModeChanged() {
        AppConfig.isNetworkWithCombine = networkModeControl.selectedSegmentIndex == 1
    }

    @objc func signOutTapped() {
        let alert = UIAlertController(
            title: "Подтверждение",
            message: "Вы действительно хотите выйти из аккаунта?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        alert.addAction(UIAlertAction(title: "Выйти", style: .destructive) { [weak self] _ in
            guard let self else { return }
            self.authManager.signOut()
            self.onSignOutConfirmed?()
        })
        present(alert, animated: true)
    }
}
