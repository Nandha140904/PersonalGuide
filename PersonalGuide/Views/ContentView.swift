// MARK: - ContentView.swift
// PersonalGuide
//
// Root view with bottom tab navigation: Home / Library / You.
// Matches the spec's information architecture.

import SwiftUI

struct ContentView: View {

    @State private var selectedTab: AppTab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label(AppTab.home.title, systemImage: AppTab.home.icon)
                }
                .tag(AppTab.home)

            LibraryView()
                .tabItem {
                    Label(AppTab.library.title, systemImage: AppTab.library.icon)
                }
                .tag(AppTab.library)

            YouView()
                .tabItem {
                    Label(AppTab.you.title, systemImage: AppTab.you.icon)
                }
                .tag(AppTab.you)
        }
        .tint(.pgPrimary)
    }
}

// MARK: - Tab Definition

enum AppTab: String, CaseIterable {
    case home
    case library
    case you

    var title: String {
        switch self {
        case .home:    return "Home"
        case .library: return "Library"
        case .you:     return "You"
        }
    }

    var icon: String {
        switch self {
        case .home:    return "house.fill"
        case .library: return "books.vertical.fill"
        case .you:     return "person.fill"
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: PGCase.self, inMemory: true)
        .environment(CaseService())
}
