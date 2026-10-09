//
//  FuelType.swift
//  PumpIT
//

import Foundation

public enum FuelType: String, CaseIterable, Codable, Identifiable, Sendable {
    case e5 = "e5"
    case e10 = "e10"
    case diesel = "diesel"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .e5: return "Super E5"
        case .e10: return "Super E10"
        case .diesel: return "Diesel"
        }
    }

    public var shortName: String {
        switch self {
        case .e5: return "E5"
        case .e10: return "E10"
        case .diesel: return "Diesel"
        }
    }
}
