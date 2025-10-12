//
//  ContentView.swift
//  OGRickandMortyQL
//
//  Created by João Gabriel Lavareda Ayres Barreto on 16/09/25.
//

import SwiftUI
import RMServerAPI


struct CharactersView: View {
     @StateObject private var viewModel = CharactersViewModelCombine()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.characters.isEmpty {
                    ProgressView("Loading characters...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = viewModel.errorMessage {
                    ErrorStateView(message: error) {
                        // retry
                        viewModel.fetchCharacters(page: 1, name: viewModel.searchText.isEmpty ? nil : viewModel.searchText)
                    }
                } else {
                    List {
                        ForEach(viewModel.characters, id: \.id) { character in
                            NavigationLink(destination: CharacterDetailView(character: character)) {
                                CharacterRow(character: character)
                            }
                            .onAppear {
                                if character.id == viewModel.characters.last?.id {
                                    viewModel.loadNextPage()
                                }
                            }
                        }

                        if viewModel.isLoading && !viewModel.characters.isEmpty {
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
            // Use a searchable bound to viewModel.searchText in both cases
            .searchable(text: $viewModel.searchText,
                        placement: .navigationBarDrawer(displayMode: .always))

            .onAppear {
                if !viewModel.isLoaded {
                    viewModel.fetchCharacters(
                        page: 1,
                        name: viewModel.searchText.isEmpty ? nil : viewModel.searchText
                    )
                }
            }
            .navigationTitle("Characters")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                viewModel.refresh()
            }
        }
    }
}

/* Keep CharacterRow and ErrorStateView definitions (reuse from your code)
   so this file can compile standalone when you paste it into the project. */

struct CharacterRow: View {
    let character: GetCharactersQuery.Data.Characters.Result

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: character.image ?? "")) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: 50, height: 50)
                case .success(let img):
                    img.resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                case .failure:
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .frame(width: 50, height: 50)
                        .foregroundStyle(.gray)
                @unknown default:
                    EmptyView()
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(character.name ?? "Unknown")
                    .font(.headline)
                Text(character.species ?? "")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct ErrorStateView: View {
    let message: String
    let retryAction: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundStyle(.orange)
            Text("Oops, something went wrong")
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Retry", action: retryAction)
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

