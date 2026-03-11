//
//  RecentGameRow.swift
//  CoachingManager
//
//  Created by Taylor Santos on 06/01/2026.
//

import SwiftUI

/// Row displaying a recent game result
struct RecentGameRow: View {
    let game: Game
    
    var body: some View {
        HStack(spacing: 12) {
            // Result indicator
            ZStack {
                Circle()
                    .fill(game.resultColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Text(game.resultString.prefix(1))
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(game.resultColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("vs \(game.opponentName)")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(game.shortDate)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(game.scoreString)
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(.primary)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray6).opacity(0.5))
        )
    }
}
