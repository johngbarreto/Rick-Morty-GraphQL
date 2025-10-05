//
//  PlanetsViewModel.swift
//  OGRickandMortyQL
//
//  Created by João Gabriel Lavareda Ayres Barreto on 22/09/25.
//

import Foundation
import RMServerAPI
import Apollo

@MainActor
final class PlanetsViewModel: ObservableObject {
    @Published var locations: [SearchLocationsQuery.Data.Locations.Result] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isLoaded = false
    @Published var searchText: String = ""
    @Published private(set) var currentPage: Int = 1
    @Published private(set) var nextPage: Int? = 1

    private let client = ApolloClient(url: URL(string: "https://rickandmortyapi.com/graphql")!)
    private var currentFetchTask: Task<Void, Never>?
    private var searchTask: Task<Void, Never>?

    // Public: cancel prior and start a fetch task (non-async caller)
    func fetchLocations(page: Int = 1, name: String? = nil) {
        currentFetchTask?.cancel()
        currentFetchTask = Task { [weak self] in
            await self?.fetchLocationsAsync(page: page, name: name)
        }
    }

    // Async worker - does the actual await call
    func fetchLocationsAsync(page: Int = 1, name: String? = nil) async {
        // Reset when starting a fresh page 1
        if page == 1 {
            locations = []
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false } // always clear loading when leaving

        let gqlName: GraphQLNullable<String> = (name?.isEmpty ?? true) ? .null : .some(name!)
        let query = SearchLocationsQuery(page: .some(page), name: gqlName)

        do {
            // `fetchAsync` must be the cancellation-aware bridge (see earlier messages)
            let result = try await client.fetchAsync(query: query)

            // if this Task was cancelled while awaiting, stop and do not apply results
            if Task.isCancelled { return }

            if let results = result.data?.locations?.results?.compactMap({ $0 }) {
                currentPage = page
                nextPage = result.data?.locations?.info?.next
                if page == 1 { locations = results } else { locations.append(contentsOf: results) }
                isLoaded = true
            } else if let errors = result.errors {
                errorMessage = errors.map(\.localizedDescription).joined(separator: "\n")
            } else {
                errorMessage = "No data returned."
            }
        } catch {
            // ignore cancellation errors
            if error is CancellationError {
                // cancelled — no UI update required
            } else {
                errorMessage = error.localizedDescription
            }
        }
    }

    // Pagination helper
    func loadNextPage() {
        guard let next = nextPage, !isLoading else { return }
        fetchLocations(page: next, name: searchText.isEmpty ? nil : searchText)
    }

    // Debounced search driven by the View (call this from .onChange)
    func search(_ text: String, debounceMilliseconds: UInt64 = 300) {
        // store the current query string for state/refresh logic
        self.searchText = text

        // cancel any pending scheduled search
        searchTask?.cancel()

        // schedule a new debounced task
        searchTask = Task { [weak self] in
            do {
                try await Task.sleep(nanoseconds: debounceMilliseconds * 1_000_000)
            } catch {
                // sleeping was cancelled -> caller typed again; just exit
                return
            }

            guard let self = self, !Task.isCancelled else { return }

            // run page 1 search
            await self.fetchLocationsAsync(page: 1, name: text.isEmpty ? nil : text)
        }
    }

    // Optional: manual refresh
    func refresh() {
        currentPage = 1
        nextPage = 1
        fetchLocations(page: 1, name: searchText.isEmpty ? nil : searchText)
    }

    deinit {
        currentFetchTask?.cancel()
        searchTask?.cancel()
    }
}
