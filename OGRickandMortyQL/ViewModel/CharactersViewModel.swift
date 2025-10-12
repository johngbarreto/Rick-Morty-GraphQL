//
//  CharactersViewModel.swift
//  OGRickandMortyQL
//
//  Created by João Gabriel Lavareda Ayres Barreto on 16/09/25.
//

import Foundation
import Combine
import Apollo 
import RMServerAPI

// MARK: - Combine-based ViewModel
@MainActor
final class CharactersViewModelCombine: ObservableObject {
    // Published state (same shape as your other VM)
    @Published var characters: [GetCharactersQuery.Data.Characters.Result] = []
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
        setupSearchPipeline()
    }

    private func setupSearchPipeline() {
        // Drop initial value if you want the view to control initial load via onAppear.
        // Remove .dropFirst() if you want the pipeline to trigger initial load automatically.
        $searchText
            .dropFirst()
            .debounce(for: .milliseconds(330), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] newText in
                guard let self = self else { return }
                self.isLoaded = false
                self.currentPage = 1
                self.nextPage = 1
                self.fetchCharacters(page: 1, name: newText.isEmpty ? nil : newText)
            }
            .store(in: &cancellables)
    }

    /// Combine-based fetch. Uses client.fetchPublisher(query:) (make sure the cancellation-aware Combine wrapper exists).
    func fetchCharacters(page: Int = 1, name: String? = nil) {
        // Cancel prior in-flight fetch
        fetchCancellable?.cancel()

        if page == 1 {
            self.characters = []
        }

        isLoading = true
        errorMessage = nil

        let gqlName: GraphQLNullable<String> = (name?.isEmpty ?? true) ? .null : .some(name!)
        let query = GetCharactersQuery(page: .some(page), name: gqlName)

        fetchCancellable = client
            .fetchPublisher(query: query) // requires cancellation-aware Combine wrapper
            .map { graphQLResult -> (results: [GetCharactersQuery.Data.Characters.Result], next: Int?) in
                let results = graphQLResult.data?.characters?.results?.compactMap { $0 } ?? []
                let next = graphQLResult.data?.characters?.info?.next
                return (results, next)
            }
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                self.isLoading = false
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
                    self.characters = value.results
                } else {
                    self.characters.append(contentsOf: value.results)
                }
                self.isLoaded = true
            })
    }

    func loadNextPage() {
        guard let next = nextPage, !isLoading else { return }
        fetchCharacters(page: next, name: searchText.isEmpty ? nil : searchText)
    }

    func refresh() {
        currentPage = 1
        nextPage = 1
        fetchCharacters(page: 1, name: searchText.isEmpty ? nil : searchText)
    }
}
