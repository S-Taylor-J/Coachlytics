//
//  CoachingManagerApp.swift
//  CoachingManager
//
//  Created by Taylor Santos on 06/01/2026.
//

import SwiftUI
import SwiftData

@main
struct CoachingManagerApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .modelContainer(for: [Player.self, Team.self, Game.self])
        }
    }
}
