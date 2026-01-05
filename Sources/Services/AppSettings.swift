import Foundation
import Security

@MainActor
final class AppSettings: ObservableObject {
    private let defaults = UserDefaults.standard

    private enum Keys {
        static let cliProxyAPIPath = "cliProxyAPIBinaryPath"
        static let cliProxyAPIVersion = "cliProxyAPIVersion"
        static let cliProxyAPIPort = "cliProxyAPIPort"
        static let cliProxyAPIConfigPath = "cliProxyAPIConfigPath"
        static let managementPort = "managementPort"
        static let binarySource = "cliProxyAPIBinarySource"
        static let keychainService = "com.flux.app"
        static let keychainAccount = "managementPassword"
    }

    @Published var cliProxyAPIPath: String? {
        didSet {
            if let path = cliProxyAPIPath {
                defaults.set(path, forKey: Keys.cliProxyAPIPath)
            } else {
                defaults.removeObject(forKey: Keys.cliProxyAPIPath)
            }
        }
    }

    @Published var binarySource: BinarySource {
        didSet {
            defaults.set(binarySource.rawValue, forKey: Keys.binarySource)
        }
    }

    @Published var cliProxyAPIVersion: String?

    @Published var cliProxyAPIPort: Int {
        didSet {
            defaults.set(cliProxyAPIPort, forKey: Keys.cliProxyAPIPort)
        }
    }

    @Published var cliProxyAPIConfigPath: String? {
        didSet {
            if let path = cliProxyAPIConfigPath {
                defaults.set(path, forKey: Keys.cliProxyAPIConfigPath)
            } else {
                defaults.removeObject(forKey: Keys.cliProxyAPIConfigPath)
            }
        }
    }

    @Published var managementPort: Int {
        didSet {
            defaults.set(managementPort, forKey: Keys.managementPort)
        }
    }

    @Published var managementPassword: String = "" {
        didSet {
            savePasswordToKeychain(managementPassword)
        }
    }

    var managementBaseURL: URL {
        URL(string: "http://127.0.0.1:\(managementPort)/v0/management")!
    }

    var effectiveCLIProxyAPIBinaryPath: String? {
        switch binarySource {
        case .managed:
            return ProxyStorageManager.shared.currentBinaryPath?.path
        case .external:
            return cliProxyAPIPath
        }
    }

    init() {
        self.cliProxyAPIPath = defaults.string(forKey: Keys.cliProxyAPIPath)
        self.cliProxyAPIVersion = defaults.string(forKey: Keys.cliProxyAPIVersion)
        self.cliProxyAPIPort = defaults.integer(forKey: Keys.cliProxyAPIPort)
        self.cliProxyAPIConfigPath = defaults.string(forKey: Keys.cliProxyAPIConfigPath)
        self.managementPort = defaults.integer(forKey: Keys.managementPort)
        self.binarySource = BinarySource(rawValue: defaults.string(forKey: Keys.binarySource) ?? "") ?? .external
        if self.cliProxyAPIPort == 0 {
            self.cliProxyAPIPort = 8317 // CLIProxyAPI default port
        }
        if self.managementPort == 0 {
            self.managementPort = 8317 // Same as proxy port
        }
        self.managementPassword = loadPasswordFromKeychain() ?? ""
    }

    // MARK: - Keychain

    private func savePasswordToKeychain(_ password: String) {
        let data = password.data(using: .utf8)!

        // Delete existing item first
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Keys.keychainService,
            kSecAttrAccount as String: Keys.keychainAccount
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        // Add new item
        guard !password.isEmpty else { return }

        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Keys.keychainService,
            kSecAttrAccount as String: Keys.keychainAccount,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]
        SecItemAdd(addQuery as CFDictionary, nil)
    }

    private func loadPasswordFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Keys.keychainService,
            kSecAttrAccount as String: Keys.keychainAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let password = String(data: data, encoding: .utf8) else {
            return nil
        }

        return password
    }
}
