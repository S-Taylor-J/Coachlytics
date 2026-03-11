//
//  PlayerStatsSheet.swift
//  CoachingManager
//
//  Created by Taylor Santos on 06/01/2026.
//

import SwiftUI

struct PlayerStatsSheet: View {
    let player: Player
    let games: [Game]
    let teamPlayers: [Player]
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    private var completedGames: [Game] {
        games.filter { $0.isCompleted }
    }
    
    private var playerEvents: [GameEvent] {
        completedGames.flatMap { game in
            game.events.filter { $0.playerId == player.id && $0.team == .ourTeam }
        }
    }
    
    private var seasonStats: PlayerGameStats {
        var infractions = 0
        var circleEntries = 0
        var goals = 0
        var turnovers = 0
        
        for event in playerEvents {
            switch event.eventType {
            case .infraction:
                infractions += 1
            case .circleEntry:
                circleEntries += 1
                if event.circleResult == .goal {
                    goals += 1
                }
            case .goal:
                goals += 1
            case .turnover:
                turnovers += 1
            }
        }
        
        return PlayerGameStats(
            totalEvents: playerEvents.count,
            infractions: infractions,
            circleEntries: circleEntries,
            goals: goals,
            turnovers: turnovers,
            gamesPlayed: completedGames.count
        )
    }
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    playerHeader
                    seasonStatsSection
                    gameBreakdownSection
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Player Stats")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Player Header
    private var playerHeader: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 70, height: 70)
                
                Text("\(player.number)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(player.name)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                
                if !player.positions.isEmpty {
                    Text(player.positions.joined(separator: ", "))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Text("\(completedGames.count) games played")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.blue)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 8, x: 0, y: 4)
        )
    }
    
    // MARK: - Season Stats Section
    private var seasonStatsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.blue)
                Text("Season Stats")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                Spacer()
            }
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                StatBox(title: "Total Events", value: "\(seasonStats.totalEvents)", color: .blue)
                StatBox(title: "Goals", value: "\(seasonStats.goals)", color: .purple)
                StatBox(title: "Circle Entries", value: "\(seasonStats.circleEntries)", color: .green)
                StatBox(title: "Infractions", value: "\(seasonStats.infractions)", color: .orange)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 8, x: 0, y: 4)
        )
    }
    
    // MARK: - Game Breakdown Section
    private var gameBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "list.bullet.rectangle")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.orange)
                Text("Game by Game")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                Spacer()
            }
            
            if completedGames.isEmpty {
                HStack {
                    Spacer()
                    Text("No completed games")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.vertical, 20)
                    Spacer()
                }
            } else {
                VStack(spacing: 8) {
                    ForEach(completedGames) { game in
                        GameStatsRow(game: game, playerId: player.id)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 8, x: 0, y: 4)
        )
    }
}
