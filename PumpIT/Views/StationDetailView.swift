//
//  StationDetailView.swift
//  PumpIT
//

import SwiftUI
import SwiftData

public struct StationDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    public let station: GasStation
    @State private var selectedTrendFuel: FuelType = .e5

    public init(station: GasStation) {
        self.station = station
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
            .navigationTitle("Gas Station")
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
        }
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
                Text(station.isOpen ? "Open" : "Closed")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(station.isOpen ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
                    .foregroundStyle(station.isOpen ? Color.green : Color.red)
                    .clipShape(Capsule())
            }

            if let dist = station.dist {
                Label(String(format: "%.1f km away", dist), systemImage: "location")
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
            Text("Current Fuel Prices")
                .font(.headline)

            HStack(spacing: 12) {
                PriceCardView(title: "Super E5", price: station.priceE5, color: .green)
                PriceCardView(title: "Super E10", price: station.priceE10, color: .teal)
                PriceCardView(title: "Diesel", price: station.priceDiesel, color: .orange)
            }
        }
    }

    // MARK: - Best Time to Fuel (24h Trend) Section
    private var bestTimeToFuelSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Best Time & 24h Trend", systemImage: "clock.badge.checkmark")
                .font(.headline)

            Picker("Fuel Type", selection: $selectedTrendFuel) {
                ForEach(FuelType.allCases) { fuel in
                    Text(fuel.shortName).tag(fuel)
                }
            }
            .pickerStyle(.segmented)

            let analysis = PriceHistoryTracker.analyzeTrend(
                station: station,
                fuelType: selectedTrendFuel,
                in: modelContext
            )

            VStack(alignment: .leading, spacing: 10) {
                if let record = analysis.lowestRecord {
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("24h Lowest Price")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(record.formattedPrice)
                                .font(.system(.title2, design: .rounded).weight(.bold))
                                .foregroundStyle(.green)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Recorded at")
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
                            Text("Optimal: Currently fueling at the 24h lowest price!")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.green)
                        }
                    } else if let diff = analysis.priceDifference {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.up.circle.fill")
                                .foregroundStyle(.orange)
                            Text(String(format: "Currently +%.3f € above 24h low", diff))
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.orange)
                        }
                    }
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.blue)
                        Text("Price history builds automatically as you browse.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "lightbulb.fill")
                        .font(.caption2)
                        .foregroundStyle(.yellow)
                        .padding(.top, 2)
                    Text(analysis.recommendation)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 2)
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
            Text("Start Navigation")
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
                        Text("Open in Apple Maps")
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
                        Text("Open in Google Maps")
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
                        Text("Open in Waze")
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

                Text("No Price")
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
