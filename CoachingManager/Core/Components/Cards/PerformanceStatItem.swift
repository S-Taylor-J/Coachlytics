//
//  PerformanceStatItem.swift
//  CoachingManager
//
//  Created by Taylor Santos on 06/01/2026.
//

import SwiftUI

/// A performance stat item for displaying metrics
struct PerformanceStatItem: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(color)
            
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    HStack {
        PerformanceStatItem(label: "Avg Goals", value: "2.5", color: .blue)
        PerformanceStatItem(label: "Avg Conceded", value: "1.2", color: .red)
        PerformanceStatItem(label: "Goal Diff", value: "+8", color: .green)
    }
    .padding()
}
