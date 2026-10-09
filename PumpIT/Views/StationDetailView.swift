//
//  StationDetailView.swift
//  PumpIT
//

import SwiftUI
import SwiftData

public struct StationDetailView: View {
    @Environment(\.dismiss) private var dismiss
    public let station: GasStation

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

                    // Navigation Routing Section
                    routingSection
                }
                .padding()
            }
            .navigationTitle("Tankstelle")
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
                Text(station.isOpen ? "Geöffnet" : "Geschlossen")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(station.isOpen ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
                    .foregroundStyle(station.isOpen ? Color.green : Color.red)
                    .clipShape(Capsule())
            }

            if let dist = station.dist {
                Label(String(format: "%.1f km entfernt", dist), systemImage: "location")
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
            Text("Aktuelle Kraftstoffpreise")
                .font(.headline)

            HStack(spacing: 12) {
                PriceCardView(title: "Super E5", price: station.priceE5, color: .green)
                PriceCardView(title: "Super E10", price: station.priceE10, color: .teal)
                PriceCardView(title: "Diesel", price: station.priceDiesel, color: .orange)
            }
        }
    }

    // MARK: - Routing Section
    private var routingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Navigation starten")
                .font(.headline)

            VStack(spacing: 10) {
                // Apple Maps Button
                Button {
                    NavigationRouter.openAppleMaps(station: station)
                } label: {
                    HStack {
                        Image(systemName: "apple.logo")
                            .font(.headline)
                        Text("In Apple Maps öffnen")
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
                    NavigationRouter.openGoogleMaps(
                        latitude: station.lat,
                        longitude: station.lng
                    )
                } label: {
                    HStack {
                        Image(systemName: "map.fill")
                            .font(.headline)
                        Text("In Google Maps öffnen")
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
                    NavigationRouter.openWaze(
                        latitude: station.lat,
                        longitude: station.lng
                    )
                } label: {
                    HStack {
                        Image(systemName: "car.fill")
                            .font(.headline)
                        Text("In Waze öffnen")
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

                Text("Kein Preis")
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
