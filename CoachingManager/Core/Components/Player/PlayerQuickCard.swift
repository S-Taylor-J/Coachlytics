//
//  PlayerQuickCard.swift
//  CoachingManager
//
//  Created by Taylor Santos on 06/01/2026.
//

import SwiftUI

/// Quick player card for horizontal scroll displays
struct PlayerQuickCard: View {
    let player: Player
    let stats: PlayerGameStats
    let onTap: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            onTap()
        }) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.brandAccent, AppTheme.brandDeepBlue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                        .shadow(color: AppTheme.brandAccent.opacity(0.3), radius: 8, x: 0, y: 4)

                    Text("\(player.number)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }

                VStack(spacing: 2) {
                    Text(player.name.split(separator: " ").first.map(String.init) ?? player.name)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.primaryText(colorScheme))
                        .lineLimit(1)

                    Text("\(stats.goals) goals")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.mutedText(colorScheme))
                }
            }
            .frame(width: 80)
            .padding(.vertical, 12)
            .cardSurface(cornerRadius: 14)
        }
    }
}

#Preview {
    PlayerQuickCard(
        player: Player(name: "John Smith", number: 10),
        stats: PlayerGameStats(totalEvents: 5, infractions: 1, circleEntries: 3, goals: 2, turnovers: 1, gamesPlayed: 5),
        onTap: {}
    )
    .padding()
}
