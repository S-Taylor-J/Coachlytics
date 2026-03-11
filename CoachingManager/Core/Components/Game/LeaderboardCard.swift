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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(color)
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
                    ForEach(Array(items.enumerated()), id: \.element.0.id) { index, item in
                        HStack(spacing: 12) {
                            // Rank
                            ZStack {
                                Circle()
                                    .fill(rankColor(for: index).opacity(0.15))
                                    .frame(width: 28, height: 28)
                                
                                Text("\(index + 1)")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundColor(rankColor(for: index))
                            }
                            
                            // Player number
                            ZStack {
                                Circle()
                                    .fill(Color.blue.opacity(0.15))
                                    .frame(width: 28, height: 28)
                                
                                Text("\(item.0.number)")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundColor(.blue)
                            }
                            
                            // Player name
                            Text(item.0.name)
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .lineLimit(1)
                            
                            Spacer()
                            
                            // Value
                            Text(item.1)
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(color)
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(.systemGray6).opacity(0.5))
                        )
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
