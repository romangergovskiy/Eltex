import UIKit

final class AuthViewController: UIViewController {

    // MARK: - Properties

    var onAuthorized: (() -> Void)?

    private let authManager: AuthSessionManager
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let loginField = UITextField()
    private let passwordField = UITextField()
    private let actionButton = UIButton(type: .system)
    private let modeControl = UISegmentedControl(items: ["Вход", "Регистрация"])
    private let stackView = UIStackView()

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
        fillLoginIfPossible()
    }
}

private extension AuthViewController {

    // MARK: - Setup

    func setupUI() {
        view.backgroundColor = UIColor(red: 0.06, green: 0.09, blue: 0.16, alpha: 1)

        [titleLabel, subtitleLabel, loginField, passwordField, actionButton, modeControl, stackView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        titleLabel.text = "Авторизация"
        titleLabel.font = .systemFont(ofSize: 34, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center

        subtitleLabel.text = "Введите логин и пароль"
        subtitleLabel.font = .systemFont(ofSize: 16, weight: .regular)
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.8)
        subtitleLabel.textAlignment = .center

        loginField.placeholder = "Логин"
        loginField.autocapitalizationType = .none
        loginField.autocorrectionType = .no
        loginField.clearButtonMode = .whileEditing
        loginField.returnKeyType = .next
        loginField.keyboardType = .asciiCapable
        loginField.backgroundColor = UIColor.white.withAlphaComponent(0.95)
        loginField.layer.cornerRadius = 12
        loginField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
        loginField.leftViewMode = .always
        loginField.delegate = self

        passwordField.placeholder = "Пароль"
        passwordField.autocapitalizationType = .none
        passwordField.autocorrectionType = .no
        passwordField.isSecureTextEntry = true
        passwordField.returnKeyType = .done
        passwordField.keyboardType = .asciiCapable
        passwordField.backgroundColor = UIColor.white.withAlphaComponent(0.95)
        passwordField.layer.cornerRadius = 12
        passwordField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
        passwordField.leftViewMode = .always
        passwordField.delegate = self

        actionButton.setTitle("Вперед", for: .normal)
        actionButton.setTitleColor(.white, for: .normal)
        actionButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        actionButton.backgroundColor = UIColor(red: 0.19, green: 0.48, blue: 0.96, alpha: 1)
        actionButton.layer.cornerRadius = 12
        actionButton.addTarget(self, action: #selector(actionTapped), for: .touchUpInside)

        modeControl.selectedSegmentIndex = AuthMode.signIn.rawValue
        modeControl.backgroundColor = UIColor.white.withAlphaComponent(0.9)
        modeControl.selectedSegmentTintColor = UIColor(red: 0.19, green: 0.48, blue: 0.96, alpha: 1)
        modeControl.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        modeControl.setTitleTextAttributes([.foregroundColor: UIColor.darkText], for: .normal)

        stackView.axis = .vertical
        stackView.spacing = 14
        stackView.addArrangedSubview(loginField)
        stackView.addArrangedSubview(passwordField)
        stackView.addArrangedSubview(actionButton)
        stackView.addArrangedSubview(modeControl)

        loginField.heightAnchor.constraint(equalToConstant: 50).isActive = true
        passwordField.heightAnchor.constraint(equalToConstant: 50).isActive = true
        actionButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        modeControl.heightAnchor.constraint(equalToConstant: 36).isActive = true

        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(stackView)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 64),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 10)
        ])
    }

    func fillLoginIfPossible() {
        if let login = authManager.storedLogin() {
            loginField.text = login
        }
    }

    func validate(login: String, password: String) -> Bool {
        let normalizedLogin = login.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        return normalizedLogin.count >= 3 && normalizedPassword.count >= 6
    }

    func showValidationAlert() {
        let alert = UIAlertController(
            title: "Некорректные данные",
            message: "Логин: минимум 3 символа. Пароль: минимум 6 символов.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "ОК", style: .default))
        present(alert, animated: true)
    }

    @objc func actionTapped() {
        let login = loginField.text ?? ""
        let password = passwordField.text ?? ""

        guard validate(login: login, password: password) else {
            showValidationAlert()
            return
        }

        let mode = AuthMode(rawValue: modeControl.selectedSegmentIndex) ?? .signIn
        switch mode {
        case .signIn:
            if authManager.signIn(login: login, password: password) {
                onAuthorized?()
            }
        case .signUp:
            if authManager.register(login: login, password: password) {
                onAuthorized?()
            }
        }
    }
}

extension AuthViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField === loginField {
            passwordField.becomeFirstResponder()
            return true
        }
        if textField === passwordField {
            textField.resignFirstResponder()
            actionTapped()
            return true
        }
        return false
    }
}
