//
//  PriceLog.swift
//  PumpIT
//

import Foundation
import SwiftData

@Model
final class PriceLog {
    var id: UUID
    var stationID: String
    var price: Double
    var timestamp: Date
    var fuelType: String

    init(
        id: UUID = UUID(),
        stationID: String,
        price: Double,
        timestamp: Date = Date(),
        fuelType: String
    ) {
        self.id = id
        self.stationID = stationID
        self.price = price
        self.timestamp = timestamp
        self.fuelType = fuelType
    }
}
