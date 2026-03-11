//
//  RootView.swift
//  CoachingManager
//
//  Created by Taylor Santos on 06/01/2026.
//

import SwiftUI

enum Tab {
    case home
    case pitch
    case game
    case add
    case settings
}

struct RootView: View {
    @State private var selectedTab: Tab = .home
    
    var body: some View {
        VStack(spacing: 0) {
            // Main content
            Group {
                switch selectedTab {
                case .home:
                    HomeView()
                case .pitch:
                    PitchView()
                case .add:
                    AddEditView()
                case .game:
                    GameListView()
                case .settings:
                    SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            CustomTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(edges: .bottom)
        .ignoresSafeArea(.keyboard)
    }
}

#Preview {
    RootView()
}

