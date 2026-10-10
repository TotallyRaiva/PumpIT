//
//  NavigationRouter.swift
//  PumpIT
//

import UIKit
import MapKit

@MainActor
public enum NavigationRouter {
    /// Opens the destination in Apple Maps using native MKMapItem.
    public static func openAppleMaps(station: GasStation) {
        let coordinate = station.coordinate
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = station.name
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }

    /// Opens Google Maps app using custom scheme comgooglemaps://, or falls back to web directions.
    public static func openGoogleMaps(latitude: Double, longitude: Double) {
        if let appURL = URL(string: "comgooglemaps://?daddr=\(latitude),\(longitude)&directionsmode=driving"),
           UIApplication.shared.canOpenURL(appURL) {
            UIApplication.shared.open(appURL)
        } else if let webURL = URL(string: "https://www.google.com/maps/dir/?api=1&destination=\(latitude),\(longitude)&travelmode=driving") {
            UIApplication.shared.open(webURL)
        }
    }

    /// Opens Waze app using custom scheme waze://, or falls back to web directions.
    public static func openWaze(latitude: Double, longitude: Double) {
        if let appURL = URL(string: "waze://?ll=\(latitude),\(longitude)&navigate=yes"),
           UIApplication.shared.canOpenURL(appURL) {
            UIApplication.shared.open(appURL)
        } else if let webURL = URL(string: "https://waze.com/ul?ll=\(latitude),\(longitude)&navigate=yes") {
            UIApplication.shared.open(webURL)
        }
    }

    /// Convenience overload to navigate to a GasStation with Google Maps
    public static func openGoogleMaps(station: GasStation) {
        openGoogleMaps(latitude: station.lat, longitude: station.lng)
    }

    /// Convenience overload to navigate to a GasStation with Waze
    public static func openWaze(station: GasStation) {
        openWaze(latitude: station.lat, longitude: station.lng)
    }
}
