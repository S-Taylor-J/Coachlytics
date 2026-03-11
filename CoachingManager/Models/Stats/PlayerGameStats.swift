//
//  PlayerGameStats.swift
//  CoachingManager
//
//  Created by Taylor Santos on 06/01/2026.
//

import Foundation

/// Statistics for a player across games
struct PlayerGameStats {
    let totalEvents: Int
    let infractions: Int
    let circleEntries: Int
    let goals: Int
    let turnovers: Int
    let gamesPlayed: Int
    
    /// Calculate player stats from completed games
    static func calculate(for player: Player, from games: [Game]) -> PlayerGameStats {
        var totalEvents = 0
        var infractions = 0
        var circleEntries = 0
        var goals = 0
        var turnovers = 0
        
        let completedGames = games.filter { $0.isCompleted }
        
        for game in completedGames {
            let playerEvents = game.events.filter { $0.playerId == player.id && $0.team == .ourTeam }
            totalEvents += playerEvents.count
            infractions += playerEvents.filter { $0.eventType == .infraction }.count
            circleEntries += playerEvents.filter { $0.eventType == .circleEntry }.count
            goals += playerEvents.filter { $0.eventType == .goal || ($0.eventType == .circleEntry && $0.circleResult == .goal) }.count
            turnovers += playerEvents.filter { $0.eventType == .turnover }.count
        }
        
        return PlayerGameStats(
            totalEvents: totalEvents,
            infractions: infractions,
            circleEntries: circleEntries,
            goals: goals,
            turnovers: turnovers,
            gamesPlayed: completedGames.count
        )
    }
}
