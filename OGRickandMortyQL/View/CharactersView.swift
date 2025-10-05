//
//  ContentView.swift
//  OGRickandMortyQL
//
//  Created by João Gabriel Lavareda Ayres Barreto on 16/09/25.
//

import SwiftUI
import RMServerAPI


struct CharactersView: View {
    // ───── PICK ONE ─────
    // 1) Use Combine version:
    // @StateObject private var viewModel = CharactersViewModelCombine()
    // 2) Use async/await version:
    @StateObject private var viewModel = CharactersViewModelAsync()
    // ─────────────────────

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
            // IMPORTANT:
            // - If you're using CharactersViewModelCombine -> DO NOT call fetch on change here (the VM pipeline handles it).
            // - If you're using CharactersViewModelAsync -> you should call the debounced search() on change.
            //
            // So **uncomment exactly one** of the blocks below depending on which VM you enabled above.

            // ----- For Combine VM: do NOTHING extra here. The VM setupSearchPipeline() handles debounced fetching.
            // .onChange(of: viewModel.searchText) { _, _ in /* no-op for Combine VM */ }

            // ----- For Async VM: call debounced search in the VM
            .onChange(of: viewModel.searchText) { _, newValue in
                // If using Combine VM, comment this line out.
                viewModel.search(newValue)
            }

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

