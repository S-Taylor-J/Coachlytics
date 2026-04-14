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

    private var totalGameTime: TimeInterval {
        completedGames.reduce(0) { total, game in
            total + game.totalPlayTime(forPlayer: player.id)
        }
    }

    private var avgGameTime: TimeInterval {
        guard !completedGames.isEmpty else { return 0 }
        return totalGameTime / Double(completedGames.count)
    }

    private var avgQuarterTime: TimeInterval {
        guard !completedGames.isEmpty else { return 0 }
        let totalQuarters = completedGames.reduce(0) { total, game in
            total + game.quarters
        }
        guard totalQuarters > 0 else { return 0 }
        return totalGameTime / Double(totalQuarters)
    }

    private func formatDuration(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
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
            .background(backgroundColor)
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
                    .fill(Color.accentColor)
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
                    .foregroundColor(Color.accentColor)
            }
            
            Spacer()
        }
        .padding(16)
        .background(cardSurface(accent: .accentColor))
    }
    
    // MARK: - Season Stats Section
    private var seasonStatsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Season Stats")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                Spacer()
            }
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                StatBox(title: "Total Events", value: "\(seasonStats.totalEvents)", color: .blue)
                StatBox(title: "Goals", value: "\(seasonStats.goals)", color: .purple)
                StatBox(title: "Circle Entries", value: "\(seasonStats.circleEntries)", color: .green)
                StatBox(title: "Infractions", value: "\(seasonStats.infractions)", color: .orange)
                StatBox(title: "Total Game Time", value: formatDuration(totalGameTime), color: .blue)
                StatBox(title: "Avg Game Time", value: formatDuration(avgGameTime), color: .mint)
                StatBox(title: "Avg Quarter Time", value: formatDuration(avgQuarterTime), color: .cyan)
            }
        }
        .padding(16)
        .background(cardSurface(accent: .blue))
    }
    
    // MARK: - Game Breakdown Section
    private var gameBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
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
        .background(cardSurface(accent: .orange))
    }

    // MARK: - Styling Helpers
    private var backgroundColor: Color {
        colorScheme == .dark ? Color(red: 0.05, green: 0.06, blue: 0.09) : Color(red: 0.97, green: 0.98, blue: 1.0)
    }

    private func cardSurface(accent: Color) -> some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(.ultraThinMaterial)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.04) : Color.white.opacity(0.6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(accent.opacity(colorScheme == .dark ? 0.4 : 0.25), lineWidth: 1)
            )
            .shadow(color: accent.opacity(colorScheme == .dark ? 0.16 : 0.12), radius: 12, x: 0, y: 8)
    }
}
