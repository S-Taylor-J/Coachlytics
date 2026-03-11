//
//  UpcomingEventRow.swift
//  CoachingManager
//
//  Created by Taylor Santos on 06/01/2026.
//

import SwiftUI

/// Row displaying an upcoming calendar event
struct UpcomingEventRow: View {
    let event: CalendarEvent
    
    private var iconName: String {
        switch event.type {
        case .game: return "sportscourt.fill"
        case .training: return "figure.run"
        case .note: return "note.text"
        }
    }
    
    private var iconColor: Color {
        switch event.type {
        case .game: return .green
        case .training: return .blue
        case .note: return .orange
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: iconName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(iconColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(formattedDate)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(daysUntil)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(iconColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(iconColor.opacity(0.15))
                )
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray6).opacity(0.5))
        )
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: event.date)
    }
    
    private var daysUntil: String {
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: Date()), to: calendar.startOfDay(for: event.date)).day ?? 0
        if days == 0 { return "Today" }
        if days == 1 { return "Tomorrow" }
        return "In \(days) days"
    }
}

#Preview {
    VStack {
        UpcomingEventRow(event: CalendarEvent(
            date: Date().addingTimeInterval(86400),
            title: "Training Session",
            type: .training
        ))
        UpcomingEventRow(event: CalendarEvent(
            date: Date().addingTimeInterval(172800),
            title: "League Match",
            type: .game
        ))
    }
    .padding()
}
