//
//  LeaderboardCard.swift
//  CoachingManager
//
//  Created by Taylor Santos on 06/01/2026.
//

import SwiftUI

/// Card displaying player leaderboard
struct LeaderboardCard: View {
    let title: String
    let icon: String
    let color: Color
    let items: [(Player, String, Int)]
    
    @Environment(\.colorScheme) private var colorScheme
    
    private struct LeaderboardRow: View {
        let index: Int
        let player: Player
        let valueText: String
        let tint: Color
        @Environment(\.colorScheme) private var colorScheme
        let rankColorProvider: (Int) -> Color

        var body: some View {
            HStack(spacing: 12) {
                // Rank
                ZStack {
                    Circle()
                        .fill(rankColorProvider(index).opacity(0.15))
                        .frame(width: 28, height: 28)

                    Text("\(index + 1)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(rankColorProvider(index))
                }

                // Player number
                ZStack {
                    Circle()
                        .fill(AppTheme.brandAccent.opacity(0.15))
                        .frame(width: 28, height: 28)

                    Text("\(player.number)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.brandAccent)
                }

                // Player name
                Text(player.name)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .lineLimit(1)

                Spacer()

                // Value
                Text(valueText)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(tint)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .cardSurface(cornerRadius: 10, showShadow: false)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                if !icon.isEmpty {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(color)
                }
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                Spacer()
            }
            
            if items.isEmpty {
                HStack {
                    Spacer()
                    Text("No data yet")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.vertical, 20)
                    Spacer()
                }
            } else {
                VStack(spacing: 8) {
                    ForEach(items.indices, id: \.self) { i in
                        let player = items[i].0
                        let valueText = items[i].1
                        LeaderboardRow(
                            index: i,
                            player: player,
                            valueText: valueText,
                            tint: color,
                            rankColorProvider: rankColor(for:)
                        )
                    }
                }
            }
        }
        .padding(16)
        .cardSurface(cornerRadius: 16, strokeAccent: color)
    }

    private func rankColor(for index: Int) -> Color {
        switch index {
        case 0: return AppTheme.goldAccent
        case 1: return .gray
        case 2: return AppTheme.warning
        default: return .secondary
        }
    }
}

#Preview {
    LeaderboardCard(
        title: "Top Scorers",
        icon: "soccerball",
        color: .purple,
        items: []
    )
    .padding()
}
