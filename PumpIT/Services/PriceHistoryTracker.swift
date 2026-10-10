//
//  PriceHistoryTracker.swift
//  PumpIT
//

import Foundation
import SwiftData

public struct LowestPriceRecord: Sendable {
    public let price: Double
    public let timestamp: Date
    public let fuelType: String

    public var formattedPrice: String {
        String(format: "%.3f €", price)
    }

    public var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: timestamp)
    }

    public var formattedDateTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E, h:mm a"
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: timestamp)
    }
}

public enum PriceHistoryTracker {
    /// Queries the SwiftData context for the lowest price of a specific station and fuel type in the last 24 hours.
    @MainActor
    public static func lowestPriceInLast24Hours(
        stationID: String,
        fuelType: FuelType,
        in modelContext: ModelContext
    ) -> LowestPriceRecord? {
        let cutoff = Date().addingTimeInterval(-24 * 3600)
        let fuelTypeRaw = fuelType.rawValue

        var descriptor = FetchDescriptor<PriceLog>(
            predicate: #Predicate { log in
                log.stationID == stationID &&
                log.fuelType == fuelTypeRaw &&
                log.timestamp >= cutoff
            },
            sortBy: [
                SortDescriptor(\.price, order: .forward),
                SortDescriptor(\.timestamp, order: .reverse)
            ]
        )
        descriptor.fetchLimit = 1

        do {
            let results = try modelContext.fetch(descriptor)
            if let lowest = results.first {
                return LowestPriceRecord(
                    price: lowest.price,
                    timestamp: lowest.timestamp,
                    fuelType: lowest.fuelType
                )
            }
        } catch {
            print("Failed to query lowest 24h price: \(error)")
        }

        return nil
    }

    /// Fetches all price logs for a station in the last 24 hours.
    @MainActor
    public static func recentLogs(
        stationID: String,
        fuelType: FuelType,
        in modelContext: ModelContext
    ) -> [PriceLog] {
        let cutoff = Date().addingTimeInterval(-24 * 3600)
        let fuelTypeRaw = fuelType.rawValue

        let descriptor = FetchDescriptor<PriceLog>(
            predicate: #Predicate { log in
                log.stationID == stationID &&
                log.fuelType == fuelTypeRaw &&
                log.timestamp >= cutoff
            },
            sortBy: [SortDescriptor(\.timestamp, order: .forward)]
        )

        return (try? modelContext.fetch(descriptor)) ?? []
    }

    /// Analyzes 24-hour price trends and provides actionable fueling recommendations.
    @MainActor
    public static func analyzeTrend(
        station: GasStation,
        fuelType: FuelType,
        in modelContext: ModelContext
    ) -> PriceTrendAnalysis {
        let lowest = lowestPriceInLast24Hours(stationID: station.id, fuelType: fuelType, in: modelContext)

        let currentPrice: Double?
        switch fuelType {
        case .e5: currentPrice = station.priceE5
        case .e10: currentPrice = station.priceE10
        case .diesel: currentPrice = station.priceDiesel
        }

        let priceDiff: Double?
        let isLow: Bool
        if let current = currentPrice, let lowest = lowest {
            let diff = current - lowest.price
            priceDiff = diff
            isLow = diff <= 0.001
        } else {
            priceDiff = nil
            isLow = false
        }

        let hour = Calendar.current.component(.hour, from: Date())
        let tip: String
        if hour >= 18 && hour <= 22 {
            tip = "Prime fueling window active! Evening prices in Germany are historically at their lowest."
        } else if hour >= 6 && hour <= 9 {
            tip = "Morning price surge: German stations peak during morning commute. Waiting until evening can save 8-12 ct/L."
        } else {
            tip = "Prices fluctuate throughout the day. In Germany, fuel tends to steadily drop toward 8:00 PM."
        }

        return PriceTrendAnalysis(
            lowestRecord: lowest,
            currentPrice: currentPrice,
            priceDifference: priceDiff,
            isAt24hLow: isLow,
            recommendation: tip
        )
    }
}

public struct PriceTrendAnalysis: Sendable {
    public let lowestRecord: LowestPriceRecord?
    public let currentPrice: Double?
    public let priceDifference: Double?
    public let isAt24hLow: Bool
    public let recommendation: String
}
