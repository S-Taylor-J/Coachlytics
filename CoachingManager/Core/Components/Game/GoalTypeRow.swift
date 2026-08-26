//
//  GoalTypeRow.swift
//  CoachingManager
//
//  Created by Taylor Santos on 06/01/2026.
//

import SwiftUI

/// Row showing goal type breakdown
struct GoalTypeRow: View {
    let type: String
    let count: Int
    let total: Int
    let color: Color
    @Environment(\.colorScheme) private var colorScheme
    
    private var percentage: Double {
        guard total > 0 else { return 0 }
        return min(max(Double(count) / Double(total), 0), 1) * 100
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Text(type)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(colorScheme == .dark ? .white.opacity(0.82) : .primary)
                .frame(width: 100, alignment: .leading)
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppTheme.strokeColor(colorScheme))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: max(geo.size.width * CGFloat(percentage) / 100, 0), height: 8)
                }
                .clipped()
            }
            .frame(height: 8)
            
            Text("\(count)")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(color)
                .frame(width: 30, alignment: .trailing)
        }
    }
}

/// Row showing game goals
struct GoalGameRow: View {
    let game: Game
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
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
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                
                Text(game.shortDate)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.52) : .secondary)
            }
            
            Spacer()
            
            Text("\(game.myTeamScore) - \(game.opponentScore)")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(colorScheme == .dark ? .white : .primary)
        }
        .padding(10)
        .cardSurface(cornerRadius: 10, showShadow: false)
    }
}

#Preview {
    VStack {
        GoalTypeRow(type: "Open Play", count: 8, total: 12, color: .blue)
        GoalTypeRow(type: "Penalty Corner", count: 3, total: 12, color: .orange)
        GoalTypeRow(type: "Stroke", count: 1, total: 12, color: .red)
    }
    .padding()
}
