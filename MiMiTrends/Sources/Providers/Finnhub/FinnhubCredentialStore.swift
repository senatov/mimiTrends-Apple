import Foundation
import Security
#if os(macOS)
import LocalAuthentication
#endif

enum FinnhubCredentialStore {
    private static let defaultService = "org.senatov.mimitrends.apple.finnhub"
    private static let account = "api-key"

    static func load(service: String = defaultService) throws -> String? {
        #if os(macOS)
        return loadMacPreference(service: service)
        #else
        var query = baseQuery(service: service)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess,
              let data = result as? Data,
              let key = String(data: data, encoding: .utf8) else {
            throw CredentialStoreError.unavailable(status)
        }
        return key
        #endif
    }

    static func save(_ key: String, service: String = defaultService) throws {
        let normalized = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { throw CredentialStoreError.emptyKey }
        #if os(macOS)
        UserDefaults.standard.set(normalized, forKey: preferenceKey(service))
        UserDefaults.standard.set(true, forKey: migrationKey(service))
        #else
        let data = Data(normalized.utf8)
        let update: [String: Any] = [kSecValueData as String: data]
        let status = SecItemUpdate(baseQuery(service: service) as CFDictionary, update as CFDictionary)
        if status == errSecSuccess { return }
        guard status == errSecItemNotFound else { throw CredentialStoreError.unavailable(status) }

        var addition = baseQuery(service: service)
        addition[kSecValueData as String] = data
        addition[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        let addStatus = SecItemAdd(addition as CFDictionary, nil)
        guard addStatus == errSecSuccess else {
            throw CredentialStoreError.unavailable(addStatus)
        }
        #endif
    }

    static func delete(service: String = defaultService) throws {
        #if os(macOS)
        UserDefaults.standard.removeObject(forKey: preferenceKey(service))
        UserDefaults.standard.set(true, forKey: migrationKey(service))
        #else
        let status = SecItemDelete(baseQuery(service: service) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw CredentialStoreError.unavailable(status)
        }
        #endif
    }

    private static func baseQuery(service: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }

    #if os(macOS)
    private static func preferenceKey(_ service: String) -> String { "credential.finnhub.\(service)" }
    private static func migrationKey(_ service: String) -> String { "credential.finnhub.migrated.\(service)" }

    private static func loadMacPreference(service: String) -> String? {
        let defaults = UserDefaults.standard
        if let stored = defaults.string(forKey: preferenceKey(service)) { return stored }
        guard !defaults.bool(forKey: migrationKey(service)) else { return nil }
        defaults.set(true, forKey: migrationKey(service))

        var query = baseQuery(service: service)
        let context = LAContext()
        context.interactionNotAllowed = true
        query[kSecUseAuthenticationContext as String] = context
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else { return nil }
        defaults.set(value, forKey: preferenceKey(service))
        return value
    }
    #endif
}

enum CredentialStoreError: LocalizedError {
    case emptyKey
    case unavailable(OSStatus)

    var errorDescription: String? {
        switch self {
        case .emptyKey: "Enter a Finnhub API key."
        case .unavailable: "Keychain is unavailable. Try again after unlocking this device."
        }
    }
}
