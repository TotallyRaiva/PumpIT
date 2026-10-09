//
//  GasStation.swift
//  PumpIT
//

import Foundation
import CoreLocation

public struct GasStation: Identifiable, Hashable, Codable, Sendable {
    public let id: String
    public let name: String
    public let brand: String?
    public let street: String?
    public let houseNumber: String?
    public let postCode: Int?
    public let place: String?
    public let lat: Double
    public let lng: Double
    public let dist: Double?
    public let priceE5: Double?
    public let priceE10: Double?
    public let priceDiesel: Double?
    public let isOpen: Bool

    public var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }

    public var formattedAddress: String {
        var components: [String] = []
        let streetLine = [street, houseNumber].compactMap { $0 }.joined(separator: " ").trimmingCharacters(in: .whitespaces)
        if !streetLine.isEmpty {
            components.append(streetLine)
        }
        let cityLine = [postCode != nil ? String(postCode!) : nil, place].compactMap { $0 }.joined(separator: " ").trimmingCharacters(in: .whitespaces)
        if !cityLine.isEmpty {
            components.append(cityLine)
        }
        return components.joined(separator: ", ")
    }

    public init(
        id: String,
        name: String,
        brand: String? = nil,
        street: String? = nil,
        houseNumber: String? = nil,
        postCode: Int? = nil,
        place: String? = nil,
        lat: Double,
        lng: Double,
        dist: Double? = nil,
        priceE5: Double? = nil,
        priceE10: Double? = nil,
        priceDiesel: Double? = nil,
        isOpen: Bool = true
    ) {
        self.id = id
        self.name = name
        self.brand = brand
        self.street = street
        self.houseNumber = houseNumber
        self.postCode = postCode
        self.place = place
        self.lat = lat
        self.lng = lng
        self.dist = dist
        self.priceE5 = priceE5
        self.priceE10 = priceE10
        self.priceDiesel = priceDiesel
        self.isOpen = isOpen
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case brand
        case street
        case houseNumber
        case postCode
        case place
        case lat
        case lng
        case dist
        case priceE5
        case priceE10
        case priceDiesel
        case e5
        case e10
        case diesel
        case isOpen
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.brand = try container.decodeIfPresent(String.self, forKey: .brand)
        self.street = try container.decodeIfPresent(String.self, forKey: .street)
        self.houseNumber = try container.decodeIfPresent(String.self, forKey: .houseNumber)
        self.postCode = try container.decodeIfPresent(Int.self, forKey: .postCode)
        self.place = try container.decodeIfPresent(String.self, forKey: .place)
        self.lat = try container.decode(Double.self, forKey: .lat)
        self.lng = try container.decode(Double.self, forKey: .lng)
        self.dist = try container.decodeIfPresent(Double.self, forKey: .dist)
        self.isOpen = try container.decodeIfPresent(Bool.self, forKey: .isOpen) ?? true

        // Tankerkönig JSON returns e5/e10/diesel as Double, or false/null when closed/unavailable.
        // We support both standard Tankerkönig keys (e5, e10, diesel) and direct keys (priceE5, priceE10, priceDiesel).
        self.priceE5 = Self.decodeFlexiblePrice(from: container, primaryKey: .priceE5, fallbackKey: .e5)
        self.priceE10 = Self.decodeFlexiblePrice(from: container, primaryKey: .priceE10, fallbackKey: .e10)
        self.priceDiesel = Self.decodeFlexiblePrice(from: container, primaryKey: .priceDiesel, fallbackKey: .diesel)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(brand, forKey: .brand)
        try container.encodeIfPresent(street, forKey: .street)
        try container.encodeIfPresent(houseNumber, forKey: .houseNumber)
        try container.encodeIfPresent(postCode, forKey: .postCode)
        try container.encodeIfPresent(place, forKey: .place)
        try container.encode(lat, forKey: .lat)
        try container.encode(lng, forKey: .lng)
        try container.encodeIfPresent(dist, forKey: .dist)
        try container.encodeIfPresent(priceE5, forKey: .priceE5)
        try container.encodeIfPresent(priceE10, forKey: .priceE10)
        try container.encodeIfPresent(priceDiesel, forKey: .priceDiesel)
        try container.encode(isOpen, forKey: .isOpen)
    }

    private static func decodeFlexiblePrice(
        from container: KeyedDecodingContainer<CodingKeys>,
        primaryKey: CodingKeys,
        fallbackKey: CodingKeys
    ) -> Double? {
        if let val = decodeSinglePrice(from: container, key: primaryKey) {
            return val
        }
        return decodeSinglePrice(from: container, key: fallbackKey)
    }

    private static func decodeSinglePrice(
        from container: KeyedDecodingContainer<CodingKeys>,
        key: CodingKeys
    ) -> Double? {
        if let doubleVal = try? container.decodeIfPresent(Double.self, forKey: key) {
            return doubleVal > 0 ? doubleVal : nil
        }
        // If API sent boolean false or string representation, handle gracefully
        if let stringVal = try? container.decodeIfPresent(String.self, forKey: key),
           let doubleVal = Double(stringVal) {
            return doubleVal > 0 ? doubleVal : nil
        }
        return nil
    }
}
