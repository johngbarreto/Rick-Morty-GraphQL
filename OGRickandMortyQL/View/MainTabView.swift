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
            Tab("Received", systemImage: "tray.and.arrow.down.fill") {
                CharactersView()
            }

            Tab("Account", systemImage: "person.crop.circle.fill") {
                PlanetsView()
            }
        }

    }
}
