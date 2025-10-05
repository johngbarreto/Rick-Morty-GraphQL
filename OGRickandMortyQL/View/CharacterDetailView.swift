//
//  CharacterDetailView.swift
//  OGRickandMortyQL
//
//  Created by João Gabriel Lavareda Ayres Barreto on 20/09/25.
//


import SwiftUI
import RMServerAPI


struct CharacterDetailView: View {
    let character: GetCharactersQuery.Data.Characters.Result
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                
                CharacterHeader(character: character)
                
                VStack(spacing: 16) {
                    CharacterInfoRow(label: "Species", value: character.species ?? "")
                    CharacterInfoRow(label: "Gender", value: character.gender ?? "")
                    CharacterStatus(status: character.status ?? "")
                    CharacterInfoRow(label: "Origin", value: character.origin?.name ?? "")
                    CharacterInfoRow(label: "Location", value: character.location?.name ?? "")
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .shadow(radius: 4, y: 2)
                
                Spacer(minLength: 40)
            }
            .padding()
        }
        .background(
            LinearGradient(
                colors: [.purple.opacity(0.2), .blue.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .navigationTitle(character.name ?? "")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct CharacterHeader: View {
    let character: GetCharactersQuery.Data.Characters.Result
    
    var body: some View {
        HStack(spacing: 12) {
            
            Text(character.name ?? "")
                .font(.largeTitle.bold())
                .foregroundStyle(.primary)
            
            AsyncImage(url: URL(string: character.image ?? "")) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: 160, height: 160)
                case .success(let img):
                    img.resizable()
                        .scaledToFill()
                        .frame(width: 160, height: 160)
                        .clipShape(Circle())
                        .shadow(radius: 8)
                case .failure:
                    Image(systemName: "person.crop.circle.fill.badge.exclam")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 160, height: 160)
                        .foregroundStyle(.gray)
                @unknown default:
                    EmptyView()
                }
            }
        }
    }
}

struct CharacterInfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.headline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.body)
                .foregroundStyle(.primary)
        }
        .padding(.vertical, 6)
    }
}

struct CharacterStatus: View {
    let status: String
    
    var body: some View {
        HStack {
            Text("Status")
                .font(.headline)
                .foregroundStyle(.secondary)
            Spacer()
            Label {
                Text(status)
                    .font(.headline)
            } icon: {
                Circle()
                    .fill(status == "Alive" ? .green : .red)
                    .frame(width: 12, height: 12)
            }
        }
        .padding(.vertical, 6)
    }
}


//#Preview {
//    NavigationStack {
//        CharacterDetailView(character: .mockRick)
//    }
//}

