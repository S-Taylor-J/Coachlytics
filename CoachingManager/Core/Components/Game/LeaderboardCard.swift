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
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 28, height: 28)

                    Text("\(player.number)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)
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
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(colorScheme == .dark ? 0.06 : 0.7))
            )
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
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.04) : Color.white.opacity(0.6))
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.black.opacity(colorScheme == .dark ? 0.12 : 0.06), lineWidth: 0.5)
            }
            .shadow(color: color.opacity(colorScheme == .dark ? 0.18 : 0.12), radius: 12, x: 0, y: 8)
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.22 : 0.08), radius: 6, x: 0, y: 3)
        )
    }
    
    private func rankColor(for index: Int) -> Color {
        switch index {
        case 0: return .yellow
        case 1: return .gray
        case 2: return .orange
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
