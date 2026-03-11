//
//  GameModels.swift
//  CoachingManager
//
//  Created by Taylor Santos on 07/01/2026.
//

import Foundation
import SwiftUI

// MARK: - Event Type Enum
enum EventType: String, CaseIterable, Codable {
    case infraction = "Infraction"
    case circleEntry = "Circle Entry"
    case turnover = "Turnover"
    case goal = "Goal"
}

// MARK: - Team Type Enum
enum TeamType: String, CaseIterable, Codable {
    case ourTeam = "Our Team"
    case otherTeam = "Opponent"
}

// MARK: - Infraction Type Enum
enum InfractionType: String, CaseIterable, Codable {
    case minor = "Minor"
    case major = "Major"
    case serious = "Serious"
    
    var description: String {
        switch self {
        case .minor: return "Foot/Stick Tackle"
        case .major: return "Significant foul"
        case .serious: return "Dangerous play"
        }
    }
}

// MARK: - Card Type Enum
enum CardType: String, CaseIterable, Codable {
    case none = "No Card"
    case green = "Green Card"
    case yellow = "Yellow Card"
    case red = "Red Card"
    
    var color: Color {
        switch self {
        case .none: return .gray
        case .green: return .green
        case .yellow: return .yellow
        case .red: return .red
        }
    }
}

// MARK: - Circle Result Enum
enum CircleResult: String, CaseIterable, Codable {
    case goal = "Goal"
    case penaltyCorner = "Penalty Corner"
    case shotSaved = "Shot Saved"
    case shotWide = "Shot Wide"
    case turnover = "Turnover"
    case longCorner = "Long Corner"
    case nothing = "Nothing"
}

// MARK: - Goal Type Enum
enum GoalType: String, CaseIterable, Codable {
    case openPlay = "Open Play"
    case penaltyCorner = "Penalty Corner"
    case stroke = "Stroke"
    
    var icon: String {
        switch self {
        case .openPlay: return "figure.run"
        case .penaltyCorner: return "flag.fill"
        case .stroke: return "target"
        }
    }
    
    var description: String {
        switch self {
        case .openPlay: return "Goal from open play"
        case .penaltyCorner: return "Goal from penalty corner"
        case .stroke: return "Goal from penalty stroke"
        }
    }
}
