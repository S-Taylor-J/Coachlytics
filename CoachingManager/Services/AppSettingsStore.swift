//
//  AppSettingsStore.swift
//  CoachingManager
//
//  Created by Taylor Santos on 06/08/2026.
//

import Foundation
import SwiftUI
import Combine

/// A singleton store for the settings that are persisted as JSON blobs in UserDefaults.
///
/// `@AppStorage` can't hold these structs directly, so views used to read them once via
/// `UserDefaults.standard` in `onAppear` (or in an initialiser default argument). Those reads
/// create no SwiftUI dependency, so edits made in Settings never reached the pitch until the
/// view happened to be rebuilt. Observing this store instead gives every screen a live value.
class AppSettingsStore: ObservableObject {
    static let shared = AppSettingsStore()

    // MARK: - Storage Keys

    static let gameSettingsKey = "gameSettingsData"

    // MARK: - Published State

    @Published var gameSettings: GameSettings {
        didSet {
            guard gameSettings != oldValue else { return }
            persistGameSettings()
        }
    }

    @Published var circleResultSettings: CircleResultSettings {
        didSet {
            guard circleResultSettings != oldValue else { return }
            circleResultSettings.saveToDefaults()
        }
    }

    // MARK: - Init

    private init() {
        gameSettings = AppSettingsStore.loadGameSettings()
        circleResultSettings = CircleResultSettings.loadFromDefaults()
    }

    // MARK: - Persistence

    private static func loadGameSettings() -> GameSettings {
        guard let settingsString = UserDefaults.standard.string(forKey: gameSettingsKey),
              let data = settingsString.data(using: .utf8),
              let settings = try? JSONDecoder().decode(GameSettings.self, from: data) else {
            return GameSettings()
        }
        return settings
    }

    private func persistGameSettings() {
        do {
            let data = try JSONEncoder().encode(gameSettings)
            // Stored as a String so it stays compatible with @AppStorage("gameSettingsData").
            UserDefaults.standard.set(String(data: data, encoding: .utf8) ?? "", forKey: AppSettingsStore.gameSettingsKey)
        } catch {
            print("Failed to save game settings: \(error)")
        }
    }

    /// Restores both settings groups to their defaults and persists them.
    func resetToDefaults() {
        gameSettings = GameSettings()
        circleResultSettings = CircleResultSettings()
    }
}
