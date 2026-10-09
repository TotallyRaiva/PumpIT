//
//  MapView.swift
//  PumpIT
//

import SwiftUI
import MapKit
import SwiftData

public struct MapView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = StationsViewModel()
    @State private var locationManager = LocationManager.shared

    public init() {}

    public var body: some View {
        ZStack(alignment: .top) {
            Map(position: $viewModel.cameraPosition) {
                UserAnnotation()

                ForEach(viewModel.stations) { station in
                    Annotation(station.name, coordinate: station.coordinate) {
                        GasStationMarkerView(
                            station: station,
                            fuelType: viewModel.selectedFuelType,
                            isSelected: viewModel.selectedStation?.id == station.id
                        )
                        .onTapGesture {
                            withAnimation {
                                viewModel.selectedStation = station
                            }
                        }
                    }
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .mapControls {
                MapCompass()
                MapScaleView()
            }
            .ignoresSafeArea(edges: .bottom)

            // Top Control Overlay
            VStack(spacing: 8) {
                topControlsHeader
                if viewModel.isLoading {
                    ProgressView("Preise werden geladen...")
                        .font(.caption)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: Capsule())
                        .shadow(radius: 2)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
        .task {
            locationManager.requestCurrentLocation()
            let centerCoord = locationManager.currentLocation ?? LocationManager.oettingenFallbackCoordinate
            await viewModel.fetchStations(around: centerCoord, context: modelContext)
        }
    }

    // MARK: - Subviews
    private var topControlsHeader: some View {
        HStack(spacing: 10) {
            // Fuel Type Picker
            Picker("Kraftstoff", selection: $viewModel.selectedFuelType) {
                ForEach(FuelType.allCases) { fuel in
                    Text(fuel.shortName).tag(fuel)
                }
            }
            .pickerStyle(.segmented)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))

            // Recenter Button
            Button {
                withAnimation {
                    viewModel.centerOnUser()
                }
            } label: {
                Image(systemName: "location.fill")
                    .font(.subheadline)
                    .padding(8)
                    .background(.ultraThinMaterial, in: Circle())
            }

            // Refresh Button
            Button {
                Task {
                    await viewModel.refreshStations(context: modelContext)
                }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.subheadline)
                    .padding(8)
                    .background(.ultraThinMaterial, in: Circle())
            }
        }
        .padding(6)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.12), radius: 6, y: 3)
    }
}
