//
//  CoachingManagerApp.swift
//  CoachingManager
//
//  Created by Taylor Santos on 06/01/2026.
//

import SwiftUI
import SwiftData
import FirebaseCore

@main
struct CoachingManagerApp: App {
    init() {
        Self.configureFirebaseIfAvailable()
    }

    var body: some Scene {
        WindowGroup {
            AppGateView()
                .modelContainer(for: [Player.self, Team.self, Game.self])
        }
    }

    /// Configures Firebase only when `GoogleService-Info.plist` has been added to the bundle.
    ///
    /// `FirebaseApp.configure()` traps if the plist is missing, which would make the app
    /// unlaunchable for anyone who hasn't set up the Firebase project yet. Checking first keeps
    /// Coachlytics fully usable offline; `AuthService` reports `.signedOut` and every account
    /// operation throws `AuthError.notConfigured` until the file is dropped in.
    private static func configureFirebaseIfAvailable() {
        guard Bundle.main.url(forResource: "GoogleService-Info", withExtension: "plist") != nil else {
            print("[Coachlytics] GoogleService-Info.plist not found — account features are disabled.")
            return
        }
        FirebaseApp.configure()
    }
}
