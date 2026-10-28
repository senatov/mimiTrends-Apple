import Foundation
import Security
#if os(macOS)
import LocalAuthentication
#endif

enum ProviderCredentialStore {
    private static let defaultService = "org.senatov.mimitrends.apple.provider-credentials"

    static func accounts(service: String = defaultService) throws -> [String] {
        #if os(macOS)
        return Array(macPreferences(service: service).keys).sorted()
        #else
        var query = serviceQuery(service)
        query[kSecReturnAttributes as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitAll
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return [] }
        guard status == errSecSuccess, let items = result as? [[String: Any]] else {
            throw ProviderCredentialError.unavailable
        }
        return items.compactMap { $0[kSecAttrAccount as String] as? String }.sorted()
        #endif
    }

    static func load(_ account: String, service: String = defaultService) throws -> String? {
        #if os(macOS)
        return macPreferences(service: service)[account]
        #else
        var query = accountQuery(account, service: service)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            throw ProviderCredentialError.unavailable
        }
        return value
        #endif
    }

    static func save(_ value: String, for account: String, service: String = defaultService) throws {
        let name = account.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, name.count <= 60,
              name.unicodeScalars.allSatisfy({ !CharacterSet.controlCharacters.contains($0) }) else {
            throw ProviderCredentialError.invalidName
        }
        let credential = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !credential.isEmpty else { throw ProviderCredentialError.emptySecret }
        #if os(macOS)
        var stored = macPreferences(service: service)
        stored[name] = credential
        UserDefaults.standard.set(stored, forKey: preferenceKey(service))
        #else
        let data = Data(credential.utf8)
        let query = accountQuery(name, service: service)
        let status = SecItemUpdate(query as CFDictionary, [kSecValueData as String: data] as CFDictionary)
        if status == errSecSuccess { return }
        guard status == errSecItemNotFound else { throw ProviderCredentialError.unavailable }

        var addition = query
        addition[kSecValueData as String] = data
        addition[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        guard SecItemAdd(addition as CFDictionary, nil) == errSecSuccess else {
            throw ProviderCredentialError.unavailable
        }
        #endif
    }

    static func delete(_ account: String, service: String = defaultService) throws {
        #if os(macOS)
        var stored = macPreferences(service: service)
        stored.removeValue(forKey: account)
        UserDefaults.standard.set(stored, forKey: preferenceKey(service))
        #else
        let status = SecItemDelete(accountQuery(account, service: service) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw ProviderCredentialError.unavailable
        }
        #endif
    }

    private static func serviceQuery(_ service: String) -> [String: Any] {
        [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service]
    }

    private static func accountQuery(_ account: String, service: String) -> [String: Any] {
        var query = serviceQuery(service)
        query[kSecAttrAccount as String] = account
        return query
    }

    #if os(macOS)
    private static func preferenceKey(_ service: String) -> String { "credential.providers.\(service)" }
    private static func migrationKey(_ service: String) -> String { "credential.providers.migrated.\(service)" }

    private static func macPreferences(service: String) -> [String: String] {
        let defaults = UserDefaults.standard
        if !defaults.bool(forKey: migrationKey(service)) {
            defaults.set(true, forKey: migrationKey(service))
            let imported = readLegacyItems(service: service)
            if !imported.isEmpty { defaults.set(imported, forKey: preferenceKey(service)) }
        }
        return defaults.dictionary(forKey: preferenceKey(service)) as? [String: String] ?? [:]
    }

    private static func readLegacyItems(service: String) -> [String: String] {
        var query = serviceQuery(service)
        let context = LAContext()
        context.interactionNotAllowed = true
        query[kSecUseAuthenticationContext as String] = context
        query[kSecReturnAttributes as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitAll
        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let items = result as? [[String: Any]] else { return [:] }

        var imported: [String: String] = [:]
        for item in items {
            guard let account = item[kSecAttrAccount as String] as? String else { continue }
            var itemQuery = accountQuery(account, service: service)
            itemQuery[kSecUseAuthenticationContext as String] = context
            itemQuery[kSecReturnData as String] = true
            itemQuery[kSecMatchLimit as String] = kSecMatchLimitOne
            var itemResult: CFTypeRef?
            guard SecItemCopyMatching(itemQuery as CFDictionary, &itemResult) == errSecSuccess,
                  let data = itemResult as? Data,
                  let value = String(data: data, encoding: .utf8) else { continue }
            imported[account] = value
        }
        return imported
    }
    #endif
}

enum ProviderCredentialError: LocalizedError {
    case invalidName
    case emptySecret
    case unavailable

    var errorDescription: String? {
        switch self {
        case .invalidName: "Enter a source name of up to 60 characters."
        case .emptySecret: "Enter an API key or token."
        case .unavailable: "Keychain is unavailable. Unlock this device and try again."
        }
    }
}
