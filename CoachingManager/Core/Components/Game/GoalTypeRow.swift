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
    
    private var percentage: Double {
        guard total > 0 else { return 0 }
        return Double(count) / Double(total) * 100
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Text(type)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.primary)
                .frame(width: 100, alignment: .leading)
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: max(geo.size.width * CGFloat(percentage) / 100, 0), height: 8)
                }
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
                
                Text(game.shortDate)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("\(game.myTeamScore) - \(game.opponentScore)")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray6).opacity(0.5))
        )
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
