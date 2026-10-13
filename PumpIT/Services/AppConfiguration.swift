//
//  AppConfiguration.swift
//  PumpIT
//

import Foundation

public enum AppConfiguration {
    /// Loads the Tankerkönig API key dynamically:
    /// 1. User-entered key in UserDefaults (if configured in settings)
    /// 2. Local gitignored Secrets.plist (for developer / production builds)
    /// 3. Fallback demo key (for public builds / previews)
    public static var tankerkoenigAPIKey: String {
        // 1. Check user override in UserDefaults
        if let userKey = UserDefaults.standard.string(forKey: "tankerkoenig_custom_api_key"),
           !userKey.trimmingCharacters(in: .whitespaces).isEmpty {
            return userKey.trimmingCharacters(in: .whitespaces)
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
}
