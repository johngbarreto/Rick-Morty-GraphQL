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
            List(viewModel.locations, id: \.id) { location in
                NavigationLink(destination: LocationDetailView(location: location)) {
                    Text(location.name ?? "Unknown")
                }
                .onAppear {
                    if location.id == viewModel.locations.last?.id {
                        viewModel.loadNextPage()
                    }
                }
            }
            .searchable(text: $viewModel.searchText,
                        placement: .navigationBarDrawer(displayMode: .always))
            // call VM.search for debounce; VM keeps searchText updated inside search()
            .onChange(of: viewModel.searchText) { _, newValue in
                viewModel.isLoaded = false
                viewModel.search(newValue)
            }
            .onAppear {
                if !viewModel.isLoaded {
                    viewModel.fetchLocations(page: 1, name: viewModel.searchText.isEmpty ? nil : viewModel.searchText)
                }
            }
            .navigationTitle("Planets")
        }
    }
}

