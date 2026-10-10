//
//  NetworkManager.swift
//  PumpIT
//

import Foundation
import SwiftData

public final class NetworkManager: Sendable {
    public static let shared = NetworkManager()

    /// Tankerkönig official public test key (works for Oettingen/demo coordinates: 48.9534, 10.6054)
    public nonisolated static let defaultAPIKey = "00000000-0000-0000-0000-000000000002"
    private static let baseURLString = "https://creativecommons.tankerkoenig.de/json/list.php"

    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    /// Fetches gas stations within a specified radius (in km) around given coordinates.
    /// - Parameters:
    ///   - latitude: Center latitude
    ///   - longitude: Center longitude
    ///   - radius: Radius in kilometers (1.0 to 25.0)
    ///   - apiKey: Tankerkönig API key (falls back to default demo key or saved key)
    /// - Returns: List of decoded `GasStation` objects
    public func fetchStations(
        latitude: Double,
        longitude: Double,
        radius: Double = 5.0,
        apiKey: String = NetworkManager.defaultAPIKey
    ) async throws -> [GasStation] {
        let clampedRadius = min(max(radius, 1.0), 25.0)

        var components = URLComponents(string: Self.baseURLString)
        components?.queryItems = [
            URLQueryItem(name: "lat", value: String(format: "%.5f", latitude)),
            URLQueryItem(name: "lng", value: String(format: "%.5f", longitude)),
            URLQueryItem(name: "rad", value: String(format: "%.1f", clampedRadius)),
            URLQueryItem(name: "sort", value: "dist"),
            URLQueryItem(name: "type", value: "all"),
            URLQueryItem(name: "apikey", value: apiKey)
        ]

        guard let url = components?.url else {
            throw NetworkError.invalidURL
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.unknown("Unexpected response format.")
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.invalidResponse(statusCode: httpResponse.statusCode)
        }

        do {
            let decoder = JSONDecoder()
            let result = try decoder.decode(TankerkoenigListResponse.self, from: data)

            if !result.ok {
                let msg = result.message ?? result.status ?? "Unknown API error"
                throw NetworkError.apiError(msg)
            }

            return result.stations ?? []
        } catch let error as NetworkError {
            throw error
        } catch {
            throw NetworkError.decodingError(error.localizedDescription)
        }
    }

    /// Saves fetched prices into SwiftData to build historical price logs.
    /// Runs on the MainActor since ModelContext is typically bound to the main actor.
    @MainActor
    public func savePriceLogs(for stations: [GasStation], in modelContext: ModelContext) {
        let now = Date()
        let fifteenMinutesAgo = now.addingTimeInterval(-15 * 60)

        for station in stations where station.isOpen {
            let priceTuples: [(FuelType, Double?)] = [
                (.e5, station.priceE5),
                (.e10, station.priceE10),
                (.diesel, station.priceDiesel)
            ]

            for (fuelType, price) in priceTuples {
                guard let price = price, price > 0 else { continue }

                // Check recent log for duplicate price within 15 minutes to avoid redundant entries
                let fuelTypeRaw = fuelType.rawValue
                let stationID = station.id
                var descriptor = FetchDescriptor<PriceLog>(
                    predicate: #Predicate { log in
                        log.stationID == stationID &&
                        log.fuelType == fuelTypeRaw &&
                        log.timestamp >= fifteenMinutesAgo
                    },
                    sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
                )
                descriptor.fetchLimit = 1

                if let recentLogs = try? modelContext.fetch(descriptor),
                   let latest = recentLogs.first,
                   abs(latest.price - price) < 0.001 {
                    // Price is identical to the entry recorded in last 15 min, skip
                    continue
                }

                let newLog = PriceLog(
                    stationID: station.id,
                    price: price,
                    timestamp: now,
                    fuelType: fuelType.rawValue
                )
                modelContext.insert(newLog)
            }
        }

        do {
            try modelContext.save()
        } catch {
            print("Failed to save SwiftData price logs: \(error.localizedDescription)")
        }
    }

    /// Asynchronously saves fetched prices into SwiftData in the background using ModelContainer.
    public func savePriceLogsInBackground(for stations: [GasStation], container: ModelContainer) async {
        let backgroundContext = ModelContext(container)
        let now = Date()
        let fifteenMinutesAgo = now.addingTimeInterval(-15 * 60)

        for station in stations where station.isOpen {
            let priceTuples: [(FuelType, Double?)] = [
                (.e5, station.priceE5),
                (.e10, station.priceE10),
                (.diesel, station.priceDiesel)
            ]

            for (fuelType, price) in priceTuples {
                guard let price = price, price > 0 else { continue }

                let fuelTypeRaw = fuelType.rawValue
                let stationID = station.id
                var descriptor = FetchDescriptor<PriceLog>(
                    predicate: #Predicate { log in
                        log.stationID == stationID &&
                        log.fuelType == fuelTypeRaw &&
                        log.timestamp >= fifteenMinutesAgo
                    },
                    sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
                )
                descriptor.fetchLimit = 1

                if let recentLogs = try? backgroundContext.fetch(descriptor),
                   let latest = recentLogs.first,
                   abs(latest.price - price) < 0.001 {
                    continue
                }

                let newLog = PriceLog(
                    stationID: station.id,
                    price: price,
                    timestamp: now,
                    fuelType: fuelType.rawValue
                )
                backgroundContext.insert(newLog)
            }
        }

        do {
            try backgroundContext.save()
        } catch {
            print("Background price caching error: \(error.localizedDescription)")
        }
    }
}

// MARK: - Tankerkönig Response Model
private struct TankerkoenigListResponse: Decodable {
    let ok: Bool
    let message: String?
    let status: String?
    let stations: [GasStation]?
}
