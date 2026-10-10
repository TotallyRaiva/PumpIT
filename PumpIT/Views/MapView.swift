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

            // Top Control Overlay with Search Bar
            VStack(spacing: 8) {
                searchBarSection
                quickCityShortcuts
                topControlsHeader

                if viewModel.isLoading {
                    ProgressView("Loading fuel prices...")
                        .font(.caption)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: Capsule())
                        .shadow(radius: 2)
                        .transition(.move(edge: .top).combined(with: .opacity))
                } else if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption2)
                        .foregroundStyle(.red)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial, in: Capsule())
                        .shadow(radius: 2)
                        .transition(.opacity)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
        .sheet(item: $viewModel.selectedStation) { station in
            StationDetailView(station: station)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .task {
            locationManager.requestCurrentLocation()
            let centerCoord = locationManager.currentLocation ?? LocationManager.oettingenFallbackCoordinate
            await viewModel.fetchStations(around: centerCoord, context: modelContext)
        }
    }

    // MARK: - Floating Search Bar
    private var searchBarSection: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .font(.subheadline)

            TextField("Search city or region in Germany...", text: $viewModel.searchQuery)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled(true)
                .submitLabel(.search)
                .onSubmit {
                    Task {
                        await viewModel.searchCity(query: viewModel.searchQuery, context: modelContext)
                    }
                }

            if viewModel.isSearchingCity {
                ProgressView()
                    .scaleEffect(0.8)
            } else if !viewModel.searchQuery.isEmpty {
                Button {
                    viewModel.searchQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            }

            Button {
                Task {
                    await viewModel.searchCity(query: viewModel.searchQuery, context: modelContext)
                }
            } label: {
                Text("Search")
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
            .disabled(viewModel.searchQuery.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.12), radius: 6, y: 3)
    }

    // MARK: - Quick City Shortcut Chips
    private var quickCityShortcuts: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(["Nürnberg", "München", "Berlin", "Frankfurt", "Hamburg", "Köln"], id: \.self) { city in
                    Button {
                        viewModel.searchQuery = city
                        Task {
                            await viewModel.searchCity(query: city, context: modelContext)
                        }
                    } label: {
                        Text(city)
                            .font(.caption.weight(.medium))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(.ultraThinMaterial, in: Capsule())
                            .foregroundStyle(.primary)
                    }
                }
            }
        }
    }

    // MARK: - Controls Header
    private var topControlsHeader: some View {
        HStack(spacing: 10) {
            // Fuel Type Picker
            Picker("Fuel Type", selection: $viewModel.selectedFuelType) {
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
