//
//  SettingsView.swift
//  PumpIT
//

import SwiftUI

public struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage(AppLanguage.storageKey) private var appLanguageRaw: String = AppLanguage.current.rawValue
    @AppStorage("default_fuel_type") private var defaultFuelType: String = FuelType.e5.rawValue
    @AppStorage("search_radius") private var searchRadius: Double = 5.0
    @AppStorage("sort_by_cheapest") private var sortByCheapest: Bool = true

    @State private var draftRadius: Double = 5.0
    @State private var customAPIKey: String = ""
    @State private var initialAPIKey: String = ""

    private let onAPIKeyChanged: (() -> Void)?

    public init(onAPIKeyChanged: (() -> Void)? = nil) {
        self.onAPIKeyChanged = onAPIKeyChanged
    }

    private var lang: AppLanguage {
        AppLanguage(rawValue: appLanguageRaw) ?? .english
    }

    public var body: some View {
        NavigationStack {
            Form {
                // MARK: - App Identity Header
                Section {
                    HStack(spacing: 16) {
                        Image(systemName: "fuelpump.fill")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(14)
                            .background(
                                LinearGradient(
                                    colors: [Color.teal, Color.green],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16))

                        VStack(alignment: .leading, spacing: 4) {
                            Text("PumpIT")
                                .font(.title3.weight(.bold))
                            Text(L10n.tr("Smart Fuel Tracker Germany", "Smarter Spritpreis-Tracker Deutschland", lang: lang))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("Version 1.0.0 (Build 1)")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                // MARK: - Language & Search Preferences
                Section(header: Text(L10n.tr("Search Preferences", "Sucheinstellungen", lang: lang))) {
                    Picker(L10n.tr("Language", "Sprache", lang: lang), selection: $appLanguageRaw) {
                        ForEach(AppLanguage.allCases) { language in
                            Text(language.displayName).tag(language.rawValue)
                        }
                    }

                    Picker(L10n.tr("Default Fuel Type", "Standard-Kraftstoff", lang: lang), selection: $defaultFuelType) {
                        ForEach(FuelType.allCases) { fuel in
                            Text(fuel.displayName).tag(fuel.rawValue)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(L10n.tr("Search Radius", "Suchradius", lang: lang))
                            Spacer()
                            Text(String(format: "%.0f km", draftRadius))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }

                        Slider(value: $draftRadius, in: 2.0...25.0, step: 1.0) { isEditing in
                            if !isEditing {
                                searchRadius = draftRadius
                            }
                        }
                        .tint(.teal)
                    }

                    Toggle(
                        L10n.tr("Sort Results by Lowest Price", "Nach günstigstem Preis sortieren", lang: lang),
                        isOn: $sortByCheapest
                    )
                }

                // MARK: - Tankerkönig API Key
                Section(
                    header: Text(L10n.tr("Tankerkönig API Key", "Tankerkönig API-Schlüssel", lang: lang)),
                    footer: Text(
                        L10n.tr(
                            "Leave empty to use the built-in secured key. You can register for your own free API key at creativecommons.tankerkoenig.de.",
                            "Leer lassen, um den integrierten Schlüssel zu verwenden. Einen eigenen kostenlosen API-Schlüssel erhalten Sie unter creativecommons.tankerkoenig.de.",
                            lang: lang
                        )
                    )
                ) {
                    SecureField(
                        L10n.tr("Custom API Key (Optional)", "Eigener API-Schlüssel (Optional)", lang: lang),
                        text: $customAPIKey
                    )
                    .autocorrectionDisabled(true)
                    .textInputAutocapitalization(.never)
                    .onChange(of: customAPIKey) { _, newValue in
                        AppConfiguration.customAPIKey = newValue
                    }

                    HStack {
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundStyle(.green)
                        Text(L10n.tr("Active & Secured in Keychain", "Aktiv & sicher im Schlüsselbund", lang: lang))
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                        Spacer()
                        if !customAPIKey.isEmpty {
                            Button(L10n.tr("Clear", "Löschen", lang: lang)) {
                                customAPIKey = ""
                                AppConfiguration.customAPIKey = ""
                                HapticFeedback.impact(style: .light)
                            }
                            .font(.caption)
                            .foregroundStyle(.red)
                        }
                    }
                }

                // MARK: - Legal & Attribution (Required by CC BY 4.0 & Apple Review)
                Section(header: Text(L10n.tr("Data & Licensing", "Daten & Lizenz", lang: lang))) {
                    Link(destination: URL(string: "https://creativecommons.tankerkoenig.de")!) {
                        HStack {
                            Text(L10n.tr("Data Provider: Tankerkönig", "Datenanbieter: Tankerkönig", lang: lang))
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Link(destination: URL(string: "https://www.bundeskartellamt.de/DE/Wirtschaftsbereiche/Mineraloel/MTS-Kraftstoffe/mtskraftstoffe_node.html")!) {
                        HStack {
                            Text(L10n.tr("Official Source: MTS-K Bundeskartellamt", "Offizielle Quelle: MTS-K Bundeskartellamt", lang: lang))
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Link(destination: URL(string: "https://totallyraiva.github.io/PumpIT/privacy.html?lang=\(lang.rawValue)")!) {
                        HStack {
                            Text(L10n.tr("Privacy Policy", "Datenschutzerklärung", lang: lang))
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Link(destination: URL(string: "https://totallyraiva.github.io/PumpIT/support.html?lang=\(lang.rawValue)")!) {
                        HStack {
                            Text(L10n.tr("Support & FAQ", "Support & Häufige Fragen", lang: lang))
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(L10n.tr("License: Creative Commons CC BY 4.0", "Lizenz: Creative Commons CC BY 4.0", lang: lang))
                            .font(.caption.weight(.semibold))
                        Text(
                            L10n.tr(
                                "All price data is retrieved from official Markttransparenzstelle für Kraftstoffe (MTS-K) feeds. Real-time prices are provided without warranty or guarantee.",
                                "Alle Preisdaten stammen von der offiziellen Markttransparenzstelle für Kraftstoffe (MTS-K). Echtzeitpreise werden ohne Gewähr bereitgestellt.",
                                lang: lang
                            )
                        )
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle(L10n.tr("Settings & About", "Einstellungen & Info", lang: lang))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.tr("Done", "Fertig", lang: lang)) {
                        HapticFeedback.impact(style: .light)
                        dismiss()
                    }
                    .font(.body.weight(.semibold))
                }
            }
            .onAppear {
                draftRadius = searchRadius
                let storedKey = AppConfiguration.customAPIKey
                customAPIKey = storedKey
                initialAPIKey = storedKey
            }
            .onDisappear {
                if draftRadius != searchRadius {
                    searchRadius = draftRadius
                }
                if customAPIKey != initialAPIKey {
                    onAPIKeyChanged?()
                }
            }
        }
        .environment(\.locale, lang.locale)
    }
}
