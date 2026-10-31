//
//  StationDetailView.swift
//  PumpIT
//

import SwiftUI
import SwiftData

public struct StationDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @AppStorage(AppLanguage.storageKey) private var appLanguageRaw: String = AppLanguage.current.rawValue

    public let station: GasStation
    @State private var selectedTrendFuel: FuelType
    @State private var trendAnalysis: PriceTrendAnalysis?

    private var lang: AppLanguage {
        AppLanguage(rawValue: appLanguageRaw) ?? .english
    }

    public init(station: GasStation, initialFuelType: FuelType = .e5) {
        self.station = station
        self._selectedTrendFuel = State(initialValue: initialFuelType)
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header info
                    headerSection

                    // Live Prices Section
                    pricesSection

                    // Best Time to Fuel (24h Trend) Section
                    bestTimeToFuelSection

                    // Navigation Routing Section
                    routingSection
                }
                .padding()
            }
            .navigationTitle(L10n.tr("Gas Station", "Tankstelle", lang: lang))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .font(.title3)
                    }
                }
            }
            .task(id: "\(selectedTrendFuel.rawValue)-\(appLanguageRaw)") {
                trendAnalysis = PriceHistoryTracker.analyzeTrend(
                    station: station,
                    fuelType: selectedTrendFuel,
                    in: modelContext
                )
            }
        }
        .environment(\.locale, lang.locale)
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    if let brand = station.brand, !brand.isEmpty {
                        Text(brand.uppercased())
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.blue)
                    }

                    Text(station.name)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.primary)

                    Text(station.formattedAddress)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Status Badge
                Text(
                    station.isOpen
                        ? L10n.tr("Open", "Geöffnet", lang: lang)
                        : L10n.tr("Closed", "Geschlossen", lang: lang)
                )
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(station.isOpen ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
                .foregroundStyle(station.isOpen ? Color.green : Color.red)
                .clipShape(Capsule())
            }

            if let dist = station.dist {
                Label(String(format: L10n.tr("%.1f km away", "%.1f km entfernt", lang: lang), dist), systemImage: "location")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Prices Section
    private var pricesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.tr("Current Fuel Prices", "Aktuelle Kraftstoffpreise", lang: lang))
                .font(.headline)

            HStack(spacing: 12) {
                PriceCardView(title: "Super E5", price: station.priceE5, color: .green, lang: lang)
                PriceCardView(title: "Super E10", price: station.priceE10, color: .teal, lang: lang)
                PriceCardView(title: "Diesel", price: station.priceDiesel, color: .orange, lang: lang)
            }
        }
    }

    // MARK: - Best Time to Fuel (24h Trend) Section
    private var bestTimeToFuelSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(
                L10n.tr("Best Time & 24h Trend", "Beste Tankzeit & 24h-Trend", lang: lang),
                systemImage: "clock.badge.checkmark"
            )
            .font(.headline)

            Picker(L10n.tr("Fuel Type", "Kraftstoff", lang: lang), selection: $selectedTrendFuel) {
                ForEach(FuelType.allCases) { fuel in
                    Text(fuel.shortName).tag(fuel)
                }
            }
            .pickerStyle(.segmented)

            VStack(alignment: .leading, spacing: 10) {
                if let analysis = trendAnalysis, let record = analysis.lowestRecord {
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(L10n.tr("24h Lowest Price", "24h-Tiefstpreis", lang: lang))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(record.formattedPrice)
                                .font(.system(.title2, design: .rounded).weight(.bold))
                                .foregroundStyle(.green)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text(L10n.tr("Recorded at", "Gemessen um", lang: lang))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(record.formattedTime)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                        }
                    }

                    Divider()

                    if analysis.isAt24hLow {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(.green)
                            Text(
                                L10n.tr(
                                    "Optimal: Currently fueling at the 24h lowest price!",
                                    "Optimal: Aktuell tanken Sie zum 24h-Tiefstpreis!",
                                    lang: lang
                                )
                            )
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.green)
                        }
                    } else if let diff = analysis.priceDifference {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.up.circle.fill")
                                .foregroundStyle(.orange)
                            Text(
                                String(
                                    format: L10n.tr(
                                        "Currently +%.3f € above 24h low",
                                        "Aktuell +%.3f € über dem 24h-Tief",
                                        lang: lang
                                    ),
                                    diff
                                )
                            )
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.orange)
                        }
                    }
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.blue)
                        Text(
                            L10n.tr(
                                "Price history builds automatically as you browse.",
                                "Der Preisverlauf wird beim Stöbern automatisch aufgebaut.",
                                lang: lang
                            )
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }

                if let recommendation = trendAnalysis?.recommendation {
                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: "lightbulb.fill")
                            .font(.caption2)
                            .foregroundStyle(.yellow)
                            .padding(.top, 2)
                        Text(recommendation)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 2)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    // MARK: - Routing Section
    private var routingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.tr("Start Navigation", "Navigation starten", lang: lang))
                .font(.headline)

            VStack(spacing: 10) {
                // Apple Maps Button
                Button {
                    HapticFeedback.impact(style: .medium)
                    NavigationRouter.openAppleMaps(station: station)
                } label: {
                    HStack {
                        Image(systemName: "apple.logo")
                            .font(.headline)
                        Text(L10n.tr("Open in Apple Maps", "In Apple Karten öffnen", lang: lang))
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // Google Maps Button
                Button {
                    HapticFeedback.impact(style: .medium)
                    NavigationRouter.openGoogleMaps(station: station)
                } label: {
                    HStack {
                        Image(systemName: "map.fill")
                            .font(.headline)
                        Text(L10n.tr("Open in Google Maps", "In Google Maps öffnen", lang: lang))
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.secondarySystemBackground))
                    .foregroundStyle(.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // Waze Button
                Button {
                    HapticFeedback.impact(style: .medium)
                    NavigationRouter.openWaze(station: station)
                } label: {
                    HStack {
                        Image(systemName: "car.fill")
                            .font(.headline)
                        Text(L10n.tr("Open in Waze", "In Waze öffnen", lang: lang))
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.secondarySystemBackground))
                    .foregroundStyle(.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }
}

// MARK: - Price Card View
private struct PriceCardView: View {
    let title: String
    let price: Double?
    let color: Color
    let lang: AppLanguage

    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)

            if let price = price, price > 0 {
                Text(String(format: "%.3f", price))
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundStyle(color)

                Text("€ / Liter")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            } else {
                Text("—")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.secondary)

                Text(L10n.tr("No Price", "Kein Preis", lang: lang))
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
