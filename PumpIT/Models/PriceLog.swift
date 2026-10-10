//
//  PriceLog.swift
//  PumpIT
//

import Foundation
import SwiftData

@Model
public final class PriceLog {
    public var id: UUID
    public var stationID: String
    public var price: Double
    public var timestamp: Date
    public var fuelType: String

    public init(
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
