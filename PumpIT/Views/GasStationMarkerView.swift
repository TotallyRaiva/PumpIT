//
//  GasStationMarkerView.swift
//  PumpIT
//

import SwiftUI

public struct GasStationMarkerView: View {
    public let station: GasStation
    public let fuelType: FuelType
    public let isSelected: Bool

    private var displayPrice: String {
        let price: Double?
        switch fuelType {
        case .e5: price = station.priceE5
        case .e10: price = station.priceE10
        case .diesel: price = station.priceDiesel
        }

        guard station.isOpen else {
            return "Geschlossen"
        }

        guard let price = price, price > 0 else {
            return "—"
        }

        return String(format: "%.2f €", price)
    }

    public var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 4) {
                Image(systemName: "fuelpump.fill")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(station.isOpen ? .white : .secondary)

                Text(displayPrice)
                    .font(.system(.caption, design: .rounded).weight(.bold))
                    .foregroundStyle(station.isOpen ? .white : .secondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(markerBackground)
                    .shadow(color: .black.opacity(isSelected ? 0.35 : 0.2), radius: isSelected ? 6 : 3, y: 2)
            )
            .overlay(
                Capsule()
                    .strokeBorder(isSelected ? Color.white : Color.clear, lineWidth: 2)
            )

            // Pointer triangle pointing to the coordinates
            Triangle()
                .fill(markerBackground)
                .frame(width: 8, height: 5)
                .offset(y: -1)
        }
        .scaleEffect(isSelected ? 1.15 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }

    private var markerBackground: Color {
        guard station.isOpen else {
            return Color.gray
        }
        if isSelected {
            return Color.blue
        }
        return Color(red: 0.1, green: 0.55, blue: 0.35) // Deep Fuel Green
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
