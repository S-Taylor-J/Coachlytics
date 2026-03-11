//
//  FormBadge.swift
//  CoachingManager
//
//  Created by Taylor Santos on 06/01/2026.
//

import SwiftUI

/// Badge showing game result (W/D/L)
struct FormBadge: View {
    let result: String
    
    private var color: Color {
        switch result {
        case "Win": return .green
        case "Loss": return .red
        default: return .gray
        }
    }
    
    private var letter: String {
        switch result {
        case "Win": return "W"
        case "Loss": return "L"
        default: return "D"
        }
    }
    
    var body: some View {
        Text(letter)
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .frame(width: 24, height: 24)
            .background(
                Circle()
                    .fill(color)
            )
    }
}

#Preview {
    HStack(spacing: 6) {
        FormBadge(result: "Win")
        FormBadge(result: "Win")
        FormBadge(result: "Draw")
        FormBadge(result: "Loss")
        FormBadge(result: "Win")
    }
    .padding()
}
