//
//  SettingsView.swift
//  PumpIT
//

import SwiftUI

public struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage("default_fuel_type") private var defaultFuelType: String = FuelType.e5.rawValue
    @AppStorage("search_radius") private var searchRadius: Double = 5.0
    @AppStorage("tankerkoenig_custom_api_key") private var customAPIKey: String = ""
    @AppStorage("sort_by_cheapest") private var sortByCheapest: Bool = true

    @State private var showingAPIKeySavedAlert = false

    public init() {}

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
                            Text("Smart Fuel Tracker Germany")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("Version 1.0.0 (Build 1)")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                // MARK: - Fuel & Search Preferences
                Section(header: Text("Search Preferences")) {
                    Picker("Default Fuel Type", selection: $defaultFuelType) {
                        ForEach(FuelType.allCases) { fuel in
                            Text(fuel.displayName).tag(fuel.rawValue)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Search Radius")
                            Spacer()
                            Text(String(format: "%.0f km", searchRadius))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }

                        Slider(value: $searchRadius, in: 2.0...25.0, step: 1.0)
                            .tint(.teal)
                    }

                    Toggle("Sort Results by Lowest Price", isOn: $sortByCheapest)
                }

                // MARK: - Tankerkönig API Key
                Section(
                    header: Text("Tankerkönig API Key"),
                    footer: Text("Leave empty to use the built-in secured key. You can register for your own free API key at creativecommons.tankerkoenig.de.")
                ) {
                    SecureField("Custom API Key (Optional)", text: $customAPIKey)
                        .autocorrectionDisabled(true)
                        .textInputAutocapitalization(.never)

                    HStack {
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundStyle(.green)
                        Text("Active & Secured")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                        Spacer()
                        if !customAPIKey.isEmpty {
                            Button("Clear") {
                                customAPIKey = ""
                                HapticFeedback.impact(style: .light)
                            }
                            .font(.caption)
                            .foregroundStyle(.red)
                        }
                    }
                }

                // MARK: - Legal & Attribution (Required by CC BY 4.0 & Apple Review)
                Section(header: Text("Data & Licensing")) {
                    Link(destination: URL(string: "https://creativecommons.tankerkoenig.de")!) {
                        HStack {
                            Text("Data Provider: Tankerkönig")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Link(destination: URL(string: "https://www.bundeskartellamt.de/DE/Wirtschaftsbereiche/Mineraloel/MTS-Kraftstoffe/mtskraftstoffe_node.html")!) {
                        HStack {
                            Text("Official Source: MTS-K Bundeskartellamt")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("License: Creative Commons CC BY 4.0")
                            .font(.caption.weight(.semibold))
                        Text("All price data is retrieved from official Markttransparenzstelle für Kraftstoffe (MTS-K) feeds. Real-time prices are provided without warranty or guarantee.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Settings & About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        HapticFeedback.impact(style: .light)
                        dismiss()
                    }
                    .font(.body.weight(.semibold))
                }
            }
        }
    }
}
