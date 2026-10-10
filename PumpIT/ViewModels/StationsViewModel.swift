//
//  StationsViewModel.swift
//  PumpIT
//

import Foundation
import SwiftUI
import MapKit
import SwiftData
import Observation

@Observable
@MainActor
public final class StationsViewModel {
    public var stations: [GasStation] = []
    public var selectedStation: GasStation?
    public var selectedFuelType: FuelType = .e5
    public var isLoading: Bool = false
    public var errorMessage: String?
    public var searchRadius: Double = 5.0

    public var cameraPosition: MapCameraPosition

    private let networkManager: NetworkManager
    private let locationManager: LocationManager

    public init(
        networkManager: NetworkManager? = nil,
        locationManager: LocationManager? = nil
    ) {
        let locManager = locationManager ?? .shared
        self.locationManager = locManager
        self.networkManager = networkManager ?? .shared

        let initialCoord = locManager.effectiveCoordinate
        self.cameraPosition = .region(
            MKCoordinateRegion(
                center: initialCoord,
                span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
            )
        )
    }

    public func refreshStations(context: ModelContext) async {
        let targetCoord = locationManager.currentLocation ?? LocationManager.oettingenFallbackCoordinate
        await fetchStations(around: targetCoord, context: context)
    }

    public func fetchStations(around coordinate: CLLocationCoordinate2D, context: ModelContext) async {
        isLoading = true
        errorMessage = nil

        do {
            let fetched = try await networkManager.fetchStations(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                radius: searchRadius
            )

            self.stations = fetched
            // Save fetched price records into SwiftData history
            networkManager.savePriceLogs(for: fetched, in: context)
        } catch {
            print("Network fetch failed: \(error.localizedDescription). Using sample data if empty.")
            if stations.isEmpty {
                // Populate sample stations near coordinate for testing/demo
                let fallbackStations = Self.sampleStations(near: coordinate)
                self.stations = fallbackStations
                networkManager.savePriceLogs(for: fallbackStations, in: context)
            }
            self.errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    public var searchQuery: String = ""
    public var isSearchingCity: Bool = false
    public var activeLocationName: String = "Current Location"

    public func searchCity(query: String, context: ModelContext) async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isSearchingCity = true
        errorMessage = nil

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = trimmed
        // Bias search towards Germany
        request.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 51.1657, longitude: 10.4515),
            span: MKCoordinateSpan(latitudeDelta: 6.0, longitudeDelta: 6.0)
        )
        request.resultTypes = [.address, .pointOfInterest]

        let search = MKLocalSearch(request: request)
        do {
            let response = try await search.start()
            guard let item = response.mapItems.first else {
                errorMessage = "No matching location found for '\(trimmed)' in Germany."
                isSearchingCity = false
                return
            }

            let coordinate = item.placemark.coordinate
            self.activeLocationName = item.name ?? item.placemark.locality ?? trimmed
            self.cameraPosition = .region(
                MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
                )
            )

            await fetchStations(around: coordinate, context: context)
        } catch {
            errorMessage = "Search failed: \(error.localizedDescription)"
        }

        isSearchingCity = false
    }

    public func centerOnUser() {
        let coord = locationManager.effectiveCoordinate
        activeLocationName = "My Location"
        cameraPosition = .region(
            MKCoordinateRegion(
                center: coord,
                span: MKCoordinateSpan(latitudeDelta: 0.06, longitudeDelta: 0.06)
            )
        )
    }

    // MARK: - Sample Demo Data
    public static func sampleStations(near coord: CLLocationCoordinate2D) -> [GasStation] {
        return [
            GasStation(
                id: "demo-aral-01",
                name: "Aral Tankstelle",
                brand: "ARAL",
                street: "Nördlinger Str.",
                houseNumber: "24",
                postCode: 86732,
                place: "Oettingen",
                lat: coord.latitude + 0.005,
                lng: coord.longitude + 0.007,
                dist: 0.8,
                priceE5: 1.749,
                priceE10: 1.689,
                priceDiesel: 1.619,
                isOpen: true
            ),
            GasStation(
                id: "demo-shell-02",
                name: "Shell Station",
                brand: "SHELL",
                street: "Donauwörther Str.",
                houseNumber: "15",
                postCode: 86732,
                place: "Oettingen",
                lat: coord.latitude - 0.006,
                lng: coord.longitude - 0.004,
                dist: 1.2,
                priceE5: 1.719,
                priceE10: 1.659,
                priceDiesel: 1.599,
                isOpen: true
            ),
            GasStation(
                id: "demo-total-03",
                name: "TotalEnergies",
                brand: "TOTAL",
                street: "Augsburger Str.",
                houseNumber: "88",
                postCode: 86732,
                place: "Oettingen",
                lat: coord.latitude + 0.008,
                lng: coord.longitude - 0.009,
                dist: 1.9,
                priceE5: 1.699,
                priceE10: 1.639,
                priceDiesel: 1.579,
                isOpen: true
            ),
            GasStation(
                id: "demo-esso-04",
                name: "Esso Station",
                brand: "ESSO",
                street: "Münchner Allee",
                houseNumber: "3",
                postCode: 86732,
                place: "Oettingen",
                lat: coord.latitude - 0.012,
                lng: coord.longitude + 0.011,
                dist: 2.4,
                priceE5: 1.779,
                priceE10: 1.719,
                priceDiesel: 1.649,
                isOpen: true
            )
        ]
    }
}
