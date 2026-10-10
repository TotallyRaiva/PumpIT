//
//  PumpITTests.swift
//  PumpITTests
//

import XCTest
import SwiftData
@testable import PumpIT

final class PumpITTests: XCTestCase {

    func testGasStationDecoding() throws {
        let json = """
        {
            "id": "test-station-123",
            "name": "Shell Express",
            "brand": "Shell",
            "street": "Hauptstrasse",
            "houseNumber": "42",
            "postCode": 86732,
            "place": "Oettingen",
            "lat": 48.9534,
            "lng": 10.6054,
            "dist": 1.5,
            "diesel": 1.629,
            "e5": 1.749,
            "e10": 1.689,
            "isOpen": true
        }
        """.data(using: .utf8)!

        let station = try JSONDecoder().decode(GasStation.self, from: json)

        XCTAssertEqual(station.id, "test-station-123")
        XCTAssertEqual(station.name, "Shell Express")
        XCTAssertEqual(station.brand, "Shell")
        XCTAssertEqual(station.priceE5, 1.749)
        XCTAssertEqual(station.priceE10, 1.689)
        XCTAssertEqual(station.priceDiesel, 1.629)
        XCTAssertTrue(station.isOpen)
        XCTAssertEqual(station.coordinate.latitude, 48.9534)
        XCTAssertEqual(station.coordinate.longitude, 10.6054)
    }

    func testGasStationDecodingWithClosedStationOrFalsePrices() throws {
        let json = """
        {
            "id": "closed-station-456",
            "name": "Aral Tankstelle",
            "lat": 48.9534,
            "lng": 10.6054,
            "diesel": false,
            "e5": false,
            "e10": false,
            "isOpen": false
        }
        """.data(using: .utf8)!

        let station = try JSONDecoder().decode(GasStation.self, from: json)
        XCTAssertEqual(station.id, "closed-station-456")
        XCTAssertNil(station.priceE5)
        XCTAssertNil(station.priceE10)
        XCTAssertNil(station.priceDiesel)
        XCTAssertFalse(station.isOpen)
    }

    @MainActor
    func testPriceHistoryTrackerLowestPriceInLast24Hours() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: PriceLog.self, configurations: config)
        let context = container.mainContext

        let stationID = "station-abc"
        let now = Date()

        // 1. Log from 2 hours ago: 1.75
        let log1 = PriceLog(
            stationID: stationID,
            price: 1.759,
            timestamp: now.addingTimeInterval(-2 * 3600),
            fuelType: FuelType.e5.rawValue
        )
        // 2. Log from 6 hours ago (lowest): 1.699
        let log2 = PriceLog(
            stationID: stationID,
            price: 1.699,
            timestamp: now.addingTimeInterval(-6 * 3600),
            fuelType: FuelType.e5.rawValue
        )
        // 3. Log from 30 hours ago (should be excluded by 24h filter): 1.500
        let log3 = PriceLog(
            stationID: stationID,
            price: 1.500,
            timestamp: now.addingTimeInterval(-30 * 3600),
            fuelType: FuelType.e5.rawValue
        )

        context.insert(log1)
        context.insert(log2)
        context.insert(log3)
        try context.save()

        let lowest = PriceHistoryTracker.lowestPriceInLast24Hours(
            stationID: stationID,
            fuelType: .e5,
            in: context
        )

        XCTAssertNotNil(lowest)
        XCTAssertEqual(lowest?.price, 1.699)
    }
}
