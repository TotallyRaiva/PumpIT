//
//  AppConfiguration.swift
//  PumpIT
//

import Foundation
import Security

public enum AppConfiguration {
    private static let legacyUserDefaultsKey = "tankerkoenig_custom_api_key"
    private static let keychainService = "raiva.PumpIT"
    private static let keychainAccount = "tankerkoenig_custom_api_key"

    /// Reads or updates the user's custom API key in the iOS Keychain (migrating any legacy UserDefaults value).
    public static var customAPIKey: String {
        get {
            if let key = readKeychainKey() {
                return key
            }
            // Migrate legacy UserDefaults key if present
            if let legacyKey = UserDefaults.standard.string(forKey: legacyUserDefaultsKey)?.trimmingCharacters(in: .whitespacesAndNewlines),
               !legacyKey.isEmpty {
                saveKeychainKey(legacyKey)
                UserDefaults.standard.removeObject(forKey: legacyUserDefaultsKey)
                return legacyKey
            }
            return ""
        }
        set {
            let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
            UserDefaults.standard.removeObject(forKey: legacyUserDefaultsKey)
            if trimmed.isEmpty {
                deleteKeychainKey()
            } else {
                saveKeychainKey(trimmed)
            }
        }
    }

    /// Loads the Tankerkönig API key dynamically:
    /// 1. User-entered key in Keychain (if configured in settings)
    /// 2. Local gitignored Secrets.plist (for developer / production builds)
    /// 3. Fallback demo key (for public builds / previews)
    public static var tankerkoenigAPIKey: String {
        // 1. Check user override in Keychain
        let userKey = customAPIKey
        if !userKey.isEmpty {
            return userKey
        }

        // 2. Check local Secrets.plist (safely gitignored)
        if let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
           let data = try? Data(contentsOf: url),
           let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any],
           let key = plist["TANKERKOENIG_API_KEY"] as? String,
           !key.isEmpty && key != "YOUR_API_KEY_HERE" {
            return key
        }

        // 3. Fallback demo key
        return "00000000-0000-0000-0000-000000000002"
    }

    // MARK: - Keychain Helpers

    private static func readKeychainKey() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        return string
    }

    private static func saveKeychainKey(_ value: String) {
        guard let data = value.data(using: .utf8) else { return }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount
        ]
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            var addQuery = query
            addQuery.merge(attributes) { _, new in new }
            SecItemAdd(addQuery as CFDictionary, nil)
        }
    }

    private static func deleteKeychainKey() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount
        ]
        SecItemDelete(query as CFDictionary)
    }
}
