//
//  GameEvent.swift
//  CoachingApp
//
//  Created by Taylor Santos on 02/01/2026.
//

import Foundation
import SwiftUI
import Combine

struct GameEvent: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let location: CGPoint
    let eventType: EventType
    let team: TeamType
    let playerId: UUID?
    let infractionType: InfractionType?
    let cardType: CardType?
    let circleResult: CircleResult?
    let goalType: GoalType?
    let quarter: Int // Track which quarter this event occurred in
    
    init(id: UUID = UUID(),
         timestamp: Date = Date(),
         location: CGPoint,
         eventType: EventType,
         team: TeamType,
         playerId: UUID? = nil,
         infractionType: InfractionType? = nil,
         cardType: CardType? = nil,
         circleResult: CircleResult? = nil,
         goalType: GoalType? = nil,
         quarter: Int = 1) {
        self.id = id
        self.timestamp = timestamp
        self.location = location
        self.eventType = eventType
        self.team = team
        self.playerId = playerId
        self.infractionType = infractionType
        self.cardType = cardType
        self.circleResult = circleResult
        self.goalType = goalType
        self.quarter = quarter
    }
}
