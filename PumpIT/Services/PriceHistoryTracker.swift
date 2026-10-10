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
}
