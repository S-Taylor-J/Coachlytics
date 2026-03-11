//
//  GameStatsRow.swift
//  CoachingManager
//
//  Created by Taylor Santos on 06/01/2026.
//

import SwiftUI

struct GameStatsRow: View {
    let game: Game
    let playerId: UUID
    
    private var playerEvents: [GameEvent] {
        game.events.filter { $0.playerId == playerId && $0.team == .ourTeam }
    }
    
    private var goals: Int {
        playerEvents.filter { $0.eventType == .goal || ($0.eventType == .circleEntry && $0.circleResult == .goal) }.count
    }
    
    private var infractions: Int {
        playerEvents.filter { $0.eventType == .infraction }.count
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Result indicator
            ZStack {
                Circle()
                    .fill(game.resultColor.opacity(0.15))
                    .frame(width: 32, height: 32)
                
                Text(game.resultString.prefix(1))
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(game.resultColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("vs \(game.opponentName)")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                
                Text(game.shortDate)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                VStack(spacing: 2) {
                    Text("\(goals)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.purple)
                    Text("Goals")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 2) {
                    Text("\(playerEvents.count)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)
                    Text("Events")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray6).opacity(0.5))
        )
    }
}
