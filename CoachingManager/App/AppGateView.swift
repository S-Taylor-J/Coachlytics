//
//  AppGateView.swift
//  CoachingManager
//

import SwiftUI
import SwiftData

/// Decides what the app shows at launch: the welcome screen, or the app itself.
///
/// The gate is deliberately **soft**. Coachlytics works entirely offline, so App Review
/// guideline 5.1.1(v) forbids requiring an account to get in — `WelcomeView` therefore always
/// offers a visible way to continue without one. An account only ever unlocks cloud backup
/// and (later) clubs.
struct AppGateView: View {
    @ObservedObject private var authService = AuthService.shared

    /// Set once the user has either signed in or explicitly chosen to skip, so returning
    /// users and existing v1.2 upgraders are never shown the welcome screen twice.
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome = false

    var body: some View {
        Group {
            if authService.state.isLoading {
                // Firebase restores a persisted session asynchronously. Holding here stops a
                // signed-in user seeing a flash of the welcome screen on every cold launch.
                LaunchPlaceholderView()
            } else if !hasSeenWelcome && !authService.state.isSignedIn {
                WelcomeView(hasSeenWelcome: $hasSeenWelcome)
                    .transition(.opacity)
            } else {
                RootView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: authService.state)
        .animation(.easeInOut(duration: 0.25), value: hasSeenWelcome)
        .onChange(of: authService.state.isSignedIn) { _, isSignedIn in
            // Signing in from Settings later on also retires the welcome screen.
            if isSignedIn { hasSeenWelcome = true }
        }
    }
}

/// Shown only for the moment it takes to restore a session.
private struct LaunchPlaceholderView: View {
    var body: some View {
        ZStack {
            AppBackgroundView()

            VStack(spacing: 18) {
                Image(systemName: "sportscourt.fill")
                    .font(.system(size: 46, weight: .bold))
                    .foregroundStyle(AppTheme.brandAccent)

                ProgressView()
                    .tint(AppTheme.brandAccent)
            }
        }
    }
}

#Preview {
    AppGateView()
        .modelContainer(for: [Player.self, Team.self, Game.self], inMemory: true)
}
