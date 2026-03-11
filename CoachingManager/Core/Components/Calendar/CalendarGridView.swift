//
//  CalendarGridView.swift
//  CoachingManager
//
//  Created by Taylor Santos on 06/01/2026.
//

import SwiftUI

/// Calendar grid view for displaying monthly schedule
struct CalendarGridView: View {
    @Binding var selectedDate: Date
    let games: [Game]
    let notes: [Date: String]
    
    private let calendar = Calendar.current
    private let daysOfWeek = ["S", "M", "T", "W", "T", "F", "S"]
    
    private var currentMonth: Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: selectedDate))!
    }
    
    private var daysInMonth: [Date?] {
        var days: [Date?] = []
        
        let range = calendar.range(of: .day, in: .month, for: currentMonth)!
        let firstWeekday = calendar.component(.weekday, from: currentMonth)
        
        // Add empty slots for days before the first day of the month
        for _ in 1..<firstWeekday {
            days.append(nil)
        }
        
        // Add all days in the month
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: currentMonth) {
                days.append(date)
            }
        }
        
        return days
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Month navigation
            HStack {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedDate = calendar.date(byAdding: .month, value: -1, to: selectedDate)!
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                Text(monthYearString)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                
                Spacer()
                
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedDate = calendar.date(byAdding: .month, value: 1, to: selectedDate)!
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.blue)
                }
            }
            
            // Days of week header
            HStack(spacing: 0) {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 6) {
                ForEach(Array(daysInMonth.enumerated()), id: \.offset) { _, date in
                    if let date = date {
                        CalendarDayCell(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            isToday: calendar.isDateInToday(date),
                            hasGame: hasGame(on: date),
                            hasNote: hasNote(on: date)
                        ) {
                            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                                selectedDate = date
                            }
                        }
                    } else {
                        Color.clear
                            .frame(height: 36)
                    }
                }
            }
        }
    }
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedDate)
    }
    
    private func hasGame(on date: Date) -> Bool {
        games.contains { calendar.isDate($0.date, inSameDayAs: date) }
    }
    
    private func hasNote(on date: Date) -> Bool {
        notes[calendar.startOfDay(for: date)] != nil
    }
}

/// Individual calendar day cell
struct CalendarDayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let hasGame: Bool
    let hasNote: Bool
    let action: () -> Void
    
    private let calendar = Calendar.current
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 14, weight: isSelected || isToday ? .bold : .medium))
                    .foregroundColor(
                        isSelected ? .white : (isToday ? .blue : .primary)
                    )
                
                // Indicators
                HStack(spacing: 2) {
                    if hasGame {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 4, height: 4)
                    }
                    if hasNote {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 4, height: 4)
                    }
                }
                .frame(height: 4)
            }
            .frame(width: 36, height: 36)
            .background(
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    } else if isToday {
                        Circle()
                            .stroke(Color.blue, lineWidth: 2)
                    }
                }
            )
        }
    }
}

#Preview {
    CalendarGridView(
        selectedDate: .constant(Date()),
        games: [],
        notes: [:]
    )
    .padding()
}
