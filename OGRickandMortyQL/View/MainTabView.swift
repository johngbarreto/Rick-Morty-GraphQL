//
//  MainTabView.swift
//  OGRickandMortyQL
//
//  Created by João Gabriel Lavareda Ayres Barreto on 22/09/25.
//


import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            Tab("Characters", systemImage: "person.crop.circle.fill") {
                CharactersView()
            }

            Tab("Locations", systemImage: "atom") {
                PlanetsView()
            }
        }

    }
}
