//
//  PlanetsViewModel.swift
//  OGRickandMortyQL
//
//  Created by João Gabriel Lavareda Ayres Barreto on 22/09/25.
//

import Foundation
import RMServerAPI
import Apollo
import Combine


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
    private var cancellables = Set<AnyCancellable>()
    private var fetchCancellable: AnyCancellable?

    init() {
        setupPlanetsSearchPipeline()
    }
    
    private func setupPlanetsSearchPipeline() {
        $searchText
            .dropFirst()
            .debounce(for: .milliseconds(330), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] newText in
                guard let self = self else { return }
                self.isLoaded = false
                self.currentPage = 1
                self.nextPage = 1
                self.fetchPlanets(page: 1, name: newText.isEmpty ? nil : newText)
            }
            .store(in: &cancellables)
    }
    
    func fetchPlanets(page: Int = 1, name: String? = nil) {
        fetchCancellable?.cancel()
        
        if page == 1 {
            self.locations = []
        }
        
        isLoading = true
        errorMessage = nil
        
        let gqlName: GraphQLNullable<String> = (name?.isEmpty ?? true) ? .null : .some(name!)
        let query = SearchLocationsQuery(page: .some(page), name: gqlName)
        
        fetchCancellable = client
            .fetchPublisher(query: query)
            .map{ graphQLResult -> (result: [SearchLocationsQuery.Data.Locations.Result], next: Int?) in
                let results = graphQLResult.data?.locations?.results?.compactMap { $0 } ?? []
                let next = graphQLResult.data?.locations?.info?.next
                return (results, next)
            }
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                switch completion {
                case .finished: break
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }, receiveValue: { [weak self] value in
                guard let self = self else { return }
                self.isLoading = false
                self.currentPage = page
                self.nextPage = value.next
                if page == 1 {
                    self.locations =  value.result
                } else {
                    self.locations.append(contentsOf: value.result)
                }
                self.isLoaded = true
            })
    }

    // Pagination helper
    func loadNextPage() {
        guard let next = nextPage, !isLoading else { return }
        fetchPlanets(page: next, name: searchText.isEmpty ? nil : searchText)

    }

    // Optional: manual refresh
    func refresh() {
        currentPage = 1
        nextPage = 1
        fetchPlanets(page: 1, name: searchText.isEmpty ? nil : searchText)
    }

}
