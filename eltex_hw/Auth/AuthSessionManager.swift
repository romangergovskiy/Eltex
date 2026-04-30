import Foundation
import Security

enum AuthMode: Int {
    case signIn = 0
    case signUp = 1
}

final class AuthSessionManager {
    static let shared = AuthSessionManager()

    private enum Keys {
        static let login = "auth.login.value"
        static let autoLoginEnabled = "auth.autoLogin.enabled"
        static let didAuthorize = "auth.session.didAuthorize"
    }

    private let defaults: UserDefaults
    private let keychainService = "com.roma.eltex-hw-10.auth"
    private let keychainAccount = "user.password"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var autoLoginEnabled: Bool {
        get { defaults.bool(forKey: Keys.autoLoginEnabled) }
        set { defaults.set(newValue, forKey: Keys.autoLoginEnabled) }
    }

    func storedLogin() -> String? {
        guard let value = defaults.string(forKey: Keys.login)?.trimmingCharacters(in: .whitespacesAndNewlines),
              !value.isEmpty else {
            return nil
        }
        return value
    }

    func canAutoLogin() -> Bool {
        autoLoginEnabled && defaults.bool(forKey: Keys.didAuthorize) && hasCredentials()
    }

    func hasCredentials() -> Bool {
        storedLogin() != nil && loadPassword() != nil
    }

    func register(login: String, password: String) -> Bool {
        let normalizedLogin = login.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedLogin.isEmpty, !normalizedPassword.isEmpty else { return false }

        guard savePassword(normalizedPassword) else { return false }
        defaults.set(normalizedLogin, forKey: Keys.login)
        defaults.set(true, forKey: Keys.didAuthorize)
        return true
    }

    func signIn(login: String, password: String) -> Bool {
        let normalizedLogin = login.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let storedLogin = storedLogin(), let storedPassword = loadPassword() else { return false }

        let isValid = normalizedLogin == storedLogin && normalizedPassword == storedPassword
        if isValid {
            defaults.set(true, forKey: Keys.didAuthorize)
        }
        return isValid
    }

    func signOut() {
        defaults.set(false, forKey: Keys.didAuthorize)
    }

    private func savePassword(_ password: String) -> Bool {
        let data = Data(password.utf8)

        let deleteQuery: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: keychainService,
            kSecAttrAccount: keychainAccount
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        let addQuery: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: keychainService,
            kSecAttrAccount: keychainAccount,
            kSecValueData: data
        ]

        let status = SecItemAdd(addQuery as CFDictionary, nil)
        return status == errSecSuccess
    }

    private func loadPassword() -> String? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: keychainService,
            kSecAttrAccount: keychainAccount,
            kSecMatchLimit: kSecMatchLimitOne,
            kSecReturnData: true
        ]

        var item: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess,
              let data = item as? Data,
              let password = String(data: data, encoding: .utf8) else {
            return nil
        }
        return password
    }
}
