//
//  SeasonStats.swift
//  CoachingManager
//
//  Created by Taylor Santos on 06/01/2026.
//

import Foundation

/// Statistics for a season of games
struct SeasonStats {
    let wins: Int
    let draws: Int
    let losses: Int
    let goalsFor: Int
    let goalsAgainst: Int
    let gamesPlayed: Int
    
    /// Win rate as a percentage (0-100)
    var winRate: Int {
        guard gamesPlayed > 0 else { return 0 }
        return Int((Double(wins) / Double(gamesPlayed)) * 100)
    }
    
    /// Average goals scored per game
    var avgGoalsFor: Double {
        guard gamesPlayed > 0 else { return 0 }
        return Double(goalsFor) / Double(gamesPlayed)
    }
    
    /// Average goals conceded per game
    var avgGoalsAgainst: Double {
        guard gamesPlayed > 0 else { return 0 }
        return Double(goalsAgainst) / Double(gamesPlayed)
    }
    
    /// Goal difference (goals for - goals against)
    var goalDifference: Int {
        goalsFor - goalsAgainst
    }
    
    /// Calculate season stats from completed games
    static func calculate(from games: [Game]) -> SeasonStats {
        let completed = games.filter { $0.isCompleted }
        let wins = completed.filter { $0.myTeamScore > $0.opponentScore }.count
        let draws = completed.filter { $0.myTeamScore == $0.opponentScore }.count
        let losses = completed.filter { $0.myTeamScore < $0.opponentScore }.count
        let goalsFor = completed.reduce(0) { $0 + $1.myTeamScore }
        let goalsAgainst = completed.reduce(0) { $0 + $1.opponentScore }
        
        return SeasonStats(
            wins: wins,
            draws: draws,
            losses: losses,
            goalsFor: goalsFor,
            goalsAgainst: goalsAgainst,
            gamesPlayed: completed.count
        )
    }
}
