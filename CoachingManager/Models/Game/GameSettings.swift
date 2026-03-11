//
//  GameSettings.swift
//  CoachingManager
//
//  Created by Taylor Santos on 06/01/2026.
//

import Foundation
import SwiftUI

// MARK: - Circle Result Appearance
struct CircleResultAppearance: Codable, Equatable {
    var colorHex: String
    var symbol: String
    
    var color: Color {
        Color(hex: colorHex) ?? .gray
    }
    
    static func defaultAppearance(for result: CircleResult) -> CircleResultAppearance {
        switch result {
        case .goal:
            return CircleResultAppearance(colorHex: "#34C759", symbol: "soccerball")
        case .penaltyCorner:
            return CircleResultAppearance(colorHex: "#FF9500", symbol: "flag.fill")
        case .shotSaved:
            return CircleResultAppearance(colorHex: "#007AFF", symbol: "hand.raised.fill")
        case .shotWide:
            return CircleResultAppearance(colorHex: "#AF52DE", symbol: "arrow.up.right")
        case .turnover:
            return CircleResultAppearance(colorHex: "#FF3B30", symbol: "arrow.triangle.2.circlepath")
        case .longCorner:
            return CircleResultAppearance(colorHex: "#5856D6", symbol: "flag.2.crossed.fill")
        case .nothing:
            return CircleResultAppearance(colorHex: "#8E8E93", symbol: "circle.dashed")
        }
    }
}

// MARK: - Circle Result Settings
struct CircleResultSettings: Codable, Equatable {
    var goalAppearance: CircleResultAppearance
    var penaltyCornerAppearance: CircleResultAppearance
    var shotSavedAppearance: CircleResultAppearance
    var shotWideAppearance: CircleResultAppearance
    var turnoverAppearance: CircleResultAppearance
    var longCornerAppearance: CircleResultAppearance
    var nothingAppearance: CircleResultAppearance
    var showSymbolsOnPitch: Bool
    var eventMarkerSize: Double // Size multiplier: 0.5 = small, 1.0 = normal, 1.5 = large
    
    init() {
        goalAppearance = CircleResultAppearance.defaultAppearance(for: .goal)
        penaltyCornerAppearance = CircleResultAppearance.defaultAppearance(for: .penaltyCorner)
        shotSavedAppearance = CircleResultAppearance.defaultAppearance(for: .shotSaved)
        shotWideAppearance = CircleResultAppearance.defaultAppearance(for: .shotWide)
        turnoverAppearance = CircleResultAppearance.defaultAppearance(for: .turnover)
        longCornerAppearance = CircleResultAppearance.defaultAppearance(for: .longCorner)
        nothingAppearance = CircleResultAppearance.defaultAppearance(for: .nothing)
        showSymbolsOnPitch = true
        eventMarkerSize = 1.0
    }
    
    func appearance(for result: CircleResult) -> CircleResultAppearance {
        switch result {
        case .goal: return goalAppearance
        case .penaltyCorner: return penaltyCornerAppearance
        case .shotSaved: return shotSavedAppearance
        case .shotWide: return shotWideAppearance
        case .turnover: return turnoverAppearance
        case .longCorner: return longCornerAppearance
        case .nothing: return nothingAppearance
        }
    }
    
    mutating func setAppearance(_ appearance: CircleResultAppearance, for result: CircleResult) {
        switch result {
        case .goal: goalAppearance = appearance
        case .penaltyCorner: penaltyCornerAppearance = appearance
        case .shotSaved: shotSavedAppearance = appearance
        case .shotWide: shotWideAppearance = appearance
        case .turnover: turnoverAppearance = appearance
        case .longCorner: longCornerAppearance = appearance
        case .nothing: nothingAppearance = appearance
        }
    }
    
    static func loadFromDefaults() -> CircleResultSettings {
        if let data = UserDefaults.standard.data(forKey: "circleResultSettings"),
           let settings = try? JSONDecoder().decode(CircleResultSettings.self, from: data) {
            return settings
        }
        return CircleResultSettings()
    }
    
    func saveToDefaults() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: "circleResultSettings")
        }
    }
}

// MARK: - Game Settings
struct GameSettings: Codable {
    var quarters: Int = 4
    var quarterDuration: Int = 900 // stored in seconds (default 15 min = 900 sec)
    var halfTimeDuration: Int = 5 // minutes
    var requirePlayerForInfractions: Bool = true // If false, only record team for infractions
    var requirePlayerForCircleEntry: Bool = false // If false, skip player selection for circle entries
    var requirePlayerForTurnover: Bool = false // If false, skip player selection for turnovers
    var circleResultSettings: CircleResultSettings = CircleResultSettings()
    
    // Computed property for backwards compatibility (values <= 120 treated as minutes)
    var quarterDurationInSeconds: Int {
        quarterDuration <= 120 ? quarterDuration * 60 : quarterDuration
    }
    
    var totalGameDuration: Int {
        // Returns total in seconds
        (quarters * quarterDurationInSeconds) + ((quarters / 2) - 1) * halfTimeDuration * 60
    }
    
    var formattedQuarterDuration: String {
        let totalSec = quarterDurationInSeconds
        let mins = totalSec / 60
        let secs = totalSec % 60
        if secs == 0 {
            return "\(mins) min"
        } else {
            return String(format: "%d:%02d", mins, secs)
        }
    }
}
