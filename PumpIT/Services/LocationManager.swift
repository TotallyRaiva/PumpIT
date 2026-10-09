//
//  LocationManager.swift
//  PumpIT
//

import Foundation
import CoreLocation
import Observation

@Observable
public final class LocationManager: NSObject, CLLocationManagerDelegate, @unchecked Sendable {
    public static let shared = LocationManager()

    /// Oettingen in Bayern coordinates (Tankerkönig reference coordinate)
    public static let oettingenFallbackCoordinate = CLLocationCoordinate2D(
        latitude: 48.9534,
        longitude: 10.6054
    )

    private let clManager = CLLocationManager()

    public var currentLocation: CLLocationCoordinate2D?
    public var authorizationStatus: CLAuthorizationStatus = .notDetermined
    public var locationError: String?

    public var effectiveCoordinate: CLLocationCoordinate2D {
        currentLocation ?? Self.oettingenFallbackCoordinate
    }

    public override init() {
        super.init()
        clManager.delegate = self
        clManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        authorizationStatus = clManager.authorizationStatus
    }

    public func requestAuthorization() {
        if authorizationStatus == .notDetermined {
            clManager.requestWhenInUseAuthorization()
        }
    }

    public func requestCurrentLocation() {
        requestAuthorization()
        clManager.requestLocation()
    }

    public func startUpdatingLocation() {
        requestAuthorization()
        clManager.startUpdatingLocation()
    }

    public func stopUpdatingLocation() {
        clManager.stopUpdatingLocation()
    }

    // MARK: - CLLocationManagerDelegate

    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            clManager.requestLocation()
        case .denied, .restricted:
            locationError = "Location access was denied. Using Oettingen as default."
        default:
            break
        }
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location.coordinate
        locationError = nil
    }

    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationError = error.localizedDescription
    }
}
