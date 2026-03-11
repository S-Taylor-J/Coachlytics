//
//  StatPill.swift
//  CoachingManager
//
//  Created by Taylor Santos on 06/01/2026.
//

import SwiftUI

/// A pill-shaped stat badge
struct StatPill: View {
    let value: String
    let color: Color
    
    var body: some View {
        Text(value)
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(color.opacity(0.15))
            )
    }
}

#Preview {
    HStack(spacing: 8) {
        StatPill(value: "5W", color: .green)
        StatPill(value: "2D", color: .gray)
        StatPill(value: "1L", color: .red)
    }
    .padding()
}
