//
//  Game.swift
//  CoachingManager
//
//  Created by Taylor Santos on 07/01/2026.
//

import Foundation
import SwiftUI
import SwiftData

@Model
class Game {
    var id: UUID
    var date: Date
    var location: String
    var notes: String
    
    // Team references
    var myTeamId: UUID?
    var myTeamName: String
    var opponentName: String
    
    // Scores
    var myTeamScore: Int
    var opponentScore: Int
    
    // Clock state (persisted)
    var isGameActive: Bool
    var isRunning: Bool
    var currentQuarter: Int
    var elapsedTime: Double
    var quarterElapsedTime: Double
    
    // Game settings
    var quarters: Int
    var quarterDuration: Int // stored in seconds (for backwards compat: values <= 120 are treated as minutes)
    
    // Computed property for actual duration in seconds (handles backwards compatibility)
    var quarterDurationInSeconds: Int {
        // If value <= 120, assume it's in minutes (old format) and convert to seconds
        // If value > 120, it's already in seconds (new format)
        quarterDuration <= 120 ? quarterDuration * 60 : quarterDuration
    }
    
    // Status
    var isCompleted: Bool
    
    // Events stored as JSON data
    var eventsData: Data?
    
    // Player play times stored as JSON data (per player per quarter)
    var playerPlayTimesData: Data?
    
    // Computed property to check if game is scheduled for the future
    var isScheduled: Bool {
        !isGameActive && !isCompleted && date > Date()
    }
    
    init(
        myTeamId: UUID? = nil,
        myTeamName: String = "My Team",
        opponentName: String = "Opponent",
        location: String = "",
        quarters: Int = 4,
        quarterDuration: Int = 15,
        scheduledDate: Date? = nil
    ) {
        self.id = UUID()
        self.date = scheduledDate ?? Date()
        self.location = location
        self.notes = ""
        self.myTeamId = myTeamId
        self.myTeamName = myTeamName
        self.opponentName = opponentName
        self.myTeamScore = 0
        self.opponentScore = 0
        self.isGameActive = false
        self.isRunning = false
        self.currentQuarter = 1
        self.elapsedTime = 0
        self.quarterElapsedTime = 0
        self.quarters = quarters
        self.quarterDuration = quarterDuration
        self.isCompleted = false
        self.eventsData = nil
        self.playerPlayTimesData = nil
    }
    
    // MARK: - Player Play Times Management
    
    /// Structure to store play time: [playerId: [quarter: seconds]]
    var playerPlayTimes: [String: [String: TimeInterval]] {
        get {
            guard let data = playerPlayTimesData else { return [:] }
            return (try? JSONDecoder().decode([String: [String: TimeInterval]].self, from: data)) ?? [:]
        }
        set {
            playerPlayTimesData = try? JSONEncoder().encode(newValue)
        }
    }
    
    /// Get total play time for a player across all quarters
    func totalPlayTime(forPlayer playerId: UUID) -> TimeInterval {
        let playerTimes = playerPlayTimes[playerId.uuidString] ?? [:]
        return playerTimes.values.reduce(0, +)
    }
    
    /// Get play time for a player in a specific quarter
    func playTime(forPlayer playerId: UUID, quarter: Int) -> TimeInterval {
        let playerTimes = playerPlayTimes[playerId.uuidString] ?? [:]
        return playerTimes["\(quarter)"] ?? 0
    }
    
    /// Update play time for a player in a specific quarter
    func updatePlayTime(forPlayer playerId: UUID, quarter: Int, time: TimeInterval) {
        var times = playerPlayTimes
        var playerTimes = times[playerId.uuidString] ?? [:]
        playerTimes["\(quarter)"] = time
        times[playerId.uuidString] = playerTimes
        playerPlayTimes = times
    }
    
    /// Get all players with their total play time
    var allPlayerPlayTimes: [(playerId: UUID, totalTime: TimeInterval)] {
        playerPlayTimes.compactMap { key, quarters in
            guard let uuid = UUID(uuidString: key) else { return nil }
            let total = quarters.values.reduce(0, +)
            return (uuid, total)
        }.sorted { $0.totalTime > $1.totalTime }
    }
    
    // MARK: - Events Management
    var events: [GameEvent] {
        get {
            guard let data = eventsData else { return [] }
            return (try? JSONDecoder().decode([GameEvent].self, from: data)) ?? []
        }
        set {
            eventsData = try? JSONEncoder().encode(newValue)
        }
    }
    
    func addEvent(_ event: GameEvent) {
        var currentEvents = events
        currentEvents.append(event)
        events = currentEvents
    }
    
    // MARK: - Quarter-based Event Methods
    
    /// Get events for a specific quarter
    func events(forQuarter quarter: Int) -> [GameEvent] {
        events.filter { $0.quarter == quarter }
    }
    
    /// Get events for all quarters up to current (for "All Game" view)
    var allGameEvents: [GameEvent] {
        events
    }
    
    /// Get events for the current quarter only (for live display)
    var currentQuarterEvents: [GameEvent] {
        events.filter { $0.quarter == currentQuarter }
    }
    
    /// Get infraction count per quarter
    func infractionCount(forQuarter quarter: Int) -> Int {
        events(forQuarter: quarter).filter { $0.eventType == .infraction }.count
    }
    
    /// Get total infractions for the game
    var totalInfractions: Int {
        events.filter { $0.eventType == .infraction }.count
    }
    
    // MARK: - Computed Properties
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    var shortDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
    
    var scoreString: String {
        "\(myTeamScore) - \(opponentScore)"
    }
    
    var resultString: String {
        if !isCompleted { return "In Progress" }
        if myTeamScore > opponentScore { return "Win" }
        if myTeamScore < opponentScore { return "Loss" }
        return "Draw"
    }
    
    var resultColor: Color {
        if !isCompleted { return .orange }
        if myTeamScore > opponentScore { return .green }
        if myTeamScore < opponentScore { return .red }
        return .gray
    }
}
