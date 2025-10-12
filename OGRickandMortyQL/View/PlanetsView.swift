//
//  PlanetsView.swift
//  OGRickandMortyQL
//
//  Created by João Gabriel Lavareda Ayres Barreto on 22/09/25.
//

import SwiftUI
import RMServerAPI

struct PlanetsView: View {
    @StateObject private var viewModel = PlanetsViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.locations.isEmpty {
                    ProgressView("Loading planets...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = viewModel.errorMessage {
                    ErrorStateView(message: error) {
                        viewModel.fetchPlanets(page: 1, name: viewModel.searchText.isEmpty ? nil : viewModel.searchText)
                    }
                } else {
                    List {
                        ForEach(viewModel.locations, id: \.id) { location in
                            NavigationLink(destination: LocationDetailView(location: location)) {
                                LocationRow(location: location)
                            }
                            .onAppear {
                                if location.id == viewModel.locations.last?.id {
                                    viewModel.loadNextPage()
                                }
                            }
                        }

                        if viewModel.isLoading && !viewModel.locations.isEmpty {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .searchable(text: $viewModel.searchText,
                        placement: .navigationBarDrawer(displayMode: .always))
            // The PlanetsViewModel's pipeline handles debounced search, so no .onChange needed.

            .onAppear {
                if !viewModel.isLoaded {
                    viewModel.fetchPlanets(page: 1, name: viewModel.searchText.isEmpty ? nil : viewModel.searchText)
                }
            }
            .navigationTitle("Locations")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                viewModel.refresh()
            }
        }
    }
}

// A simple row for a Location (no image in the API — use an icon)
struct LocationRow: View {
    let location: SearchLocationsQuery.Data.Locations.Result

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "globe")
                .resizable()
                .scaledToFit()
                .frame(width: 44, height: 44)
                .padding(6)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text(location.name ?? "Unknown")
                    .font(.headline)

                HStack(spacing: 8) {
                    if let type = location.type, !type.isEmpty {
                        Text(type)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    if let dimension = location.dimension, !dimension.isEmpty {
                        Text(dimension)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 6)
    }
}
