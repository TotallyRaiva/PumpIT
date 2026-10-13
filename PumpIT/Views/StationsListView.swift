//
//  StationsListView.swift
//  PumpIT
//

import SwiftUI

public struct StationsListView: View {
    public let stations: [GasStation]
    public let fuelType: FuelType
    public let onSelectStation: (GasStation) -> Void

    @AppStorage("sort_by_cheapest") private var sortByCheapest: Bool = true

    public init(
        stations: [GasStation],
        fuelType: FuelType,
        onSelectStation: @escaping (GasStation) -> Void
    ) {
        self.stations = stations
        self.fuelType = fuelType
        self.onSelectStation = onSelectStation
    }

    private var sortedStations: [GasStation] {
        if sortByCheapest {
            return stations.sorted { s1, s2 in
                let p1 = price(for: s1) ?? 999
                let p2 = price(for: s2) ?? 999
                return p1 < p2
            }
        } else {
            return stations.sorted { ($0.dist ?? 999) < ($1.dist ?? 999) }
        }
    }

    private func price(for station: GasStation) -> Double? {
        switch fuelType {
        case .e5: return station.priceE5
        case .e10: return station.priceE10
        case .diesel: return station.priceDiesel
        }
    }

    private var lowestPrice: Double? {
        stations.compactMap { price(for: $0) }.filter { $0 > 0 }.min()
    }

    public var body: some View {
        if stations.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "fuelpump.slash")
                    .font(.system(size: 44))
                    .foregroundStyle(.secondary)
                Text("No Gas Stations Found")
                    .font(.headline)
                Text("Try expanding your search radius or searching for another city.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List(sortedStations) { station in
                Button {
                    HapticFeedback.selection()
                    onSelectStation(station)
                } label: {
                    HStack(spacing: 12) {
                        // Brand Icon
                        VStack {
                            Image(systemName: "fuelpump.fill")
                                .font(.headline)
                                .foregroundStyle(station.isOpen ? .white : .secondary)
                        }
                        .frame(width: 44, height: 44)
                        .background(station.isOpen ? Color.teal : Color(.systemGray4))
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                        // Station Details
                        VStack(alignment: .leading, spacing: 3) {
                            HStack {
                                Text(station.name)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)

                                if let p = price(for: station), let low = lowestPrice, abs(p - low) < 0.001 {
                                    Text("BEST")
                                        .font(.system(size: 9, weight: .bold))
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 2)
                                        .background(Color.green)
                                        .foregroundStyle(.white)
                                        .clipShape(Capsule())
                                }
                            }

                            Text(station.formattedAddress)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)

                            if let dist = station.dist {
                                Text(String(format: "%.1f km away", dist))
                                    .font(.caption2.weight(.medium))
                                    .foregroundStyle(.tertiary)
                            }
                        }

                        Spacer()

                        // Price Display
                        VStack(alignment: .trailing, spacing: 2) {
                            if let p = price(for: station), p > 0 {
                                Text(String(format: "%.3f €", p))
                                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                                    .foregroundStyle(station.isOpen ? .primary : .secondary)

                                Text(fuelType.shortName)
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("—")
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(.secondary)
                                Text("No Price")
                                    .font(.system(size: 9))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .listStyle(.plain)
        }
    }
}
