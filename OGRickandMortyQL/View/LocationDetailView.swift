//
//  CharacterDetailView 2.swift
//  OGRickandMortyQL
//
//  Created by João Gabriel Lavareda Ayres Barreto on 22/09/25.
//


import SwiftUI
import RMServerAPI

struct LocationDetailView: View {
    let location: SearchLocationsQuery.Data.Locations.Result

    var body: some View {
        VStack(spacing: 20) {
            Text(location.name ?? "Unknown")
                .font(.title)
                .bold()

            if let species = location.dimension {
                Text("Species: \(species)")
            }

            if let status = location.type {
                Text("Status: \(status)")
                    .foregroundColor(status == "Alive" ? .green : .red)
            }

            Spacer()
        }
        .padding()
        .navigationTitle(location.name ?? "Character")
    }
}
