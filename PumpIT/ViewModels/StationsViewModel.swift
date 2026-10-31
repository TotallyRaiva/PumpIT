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
    public private(set) var activeSearchCoordinate: CLLocationCoordinate2D

    private let networkManager: NetworkManager
    private let locationManager: LocationManager
    private var hasCenteredOnInitialUserLocation: Bool = false
    private var isUsingCustomCitySearch: Bool = false

    public init(
        networkManager: NetworkManager? = nil,
        locationManager: LocationManager? = nil
    ) {
        let locManager = locationManager ?? .shared
        self.locationManager = locManager
        self.networkManager = networkManager ?? .shared

        let initialCoord = locManager.effectiveCoordinate
        self.activeSearchCoordinate = initialCoord
        self.hasCenteredOnInitialUserLocation = (locManager.currentLocation != nil)
        self.cameraPosition = .region(
            MKCoordinateRegion(
                center: initialCoord,
                span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
            )
        )
    }

    public func refreshStations(context: ModelContext) async {
        if !isUsingCustomCitySearch, let userCoord = locationManager.currentLocation {
            activeSearchCoordinate = userCoord
        }
        await fetchStations(around: activeSearchCoordinate, context: context)
    }

    public func handleLocationUpdate(context: ModelContext) async {
        guard let userCoord = locationManager.currentLocation else { return }
        guard !hasCenteredOnInitialUserLocation && !isUsingCustomCitySearch else { return }

        hasCenteredOnInitialUserLocation = true
        activeSearchCoordinate = userCoord
        activeLocationName = "Current Location"
        cameraPosition = .region(
            MKCoordinateRegion(
                center: userCoord,
                span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
            )
        )
        await fetchStations(around: userCoord, context: context)
    }

    public func fetchStations(around coordinate: CLLocationCoordinate2D, context: ModelContext) async {
        isLoading = true
        errorMessage = nil
        activeSearchCoordinate = coordinate

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
            if error is CancellationError {
                isLoading = false
                return
            }
            print("Network fetch failed: \(error.localizedDescription). Using sample data if empty.")
            if stations.isEmpty {
                // Populate sample stations near coordinate for testing/demo without polluting SwiftData
                self.stations = Self.sampleStations(near: coordinate)
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
                errorMessage = L10n.tr(
                    "No matching location found for '\(trimmed)' in Germany.",
                    "Kein passender Ort für '\(trimmed)' in Deutschland gefunden."
                )
                isSearchingCity = false
                return
            }

            let coordinate = item.placemark.coordinate
            self.isUsingCustomCitySearch = true
            self.activeSearchCoordinate = coordinate
            self.activeLocationName = item.name ?? item.placemark.locality ?? trimmed
            self.cameraPosition = .region(
                MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
                )
            )

            await fetchStations(around: coordinate, context: context)
        } catch {
            errorMessage = L10n.tr(
                "Search failed: \(error.localizedDescription)",
                "Suche fehlgeschlagen: \(error.localizedDescription)"
            )
        }

        isSearchingCity = false
    }

    public func centerOnUser(context: ModelContext? = nil) async {
        isUsingCustomCitySearch = false
        locationManager.requestCurrentLocation()
        let coord = locationManager.effectiveCoordinate
        activeSearchCoordinate = coord
        activeLocationName = "My Location"
        cameraPosition = .region(
            MKCoordinateRegion(
                center: coord,
                span: MKCoordinateSpan(latitudeDelta: 0.06, longitudeDelta: 0.06)
            )
        )
        if let context {
            await fetchStations(around: coord, context: context)
        }
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
