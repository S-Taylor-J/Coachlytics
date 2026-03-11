//
//  Date+Formatting.swift
//  CoachingManager
//
//  Created by Taylor Santos on 06/01/2026.
//

import Foundation

extension Date {
    /// Format date for display (e.g., "Jan 15, 2026 at 3:30 PM")
    var formattedMedium: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
    
    /// Short date format (e.g., "Jan 15")
    var shortFormat: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: self)
    }
    
    /// Day of week format (e.g., "Monday")
    var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: self)
    }
    
    /// Full date format (e.g., "January 15, 2026")
    var fullDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: self)
    }
    
    /// Returns greeting based on time of day
    var timeOfDayGreeting: String {
        let hour = Calendar.current.component(.hour, from: self)
        switch hour {
        case 0..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        default: return "Good Evening"
        }
    }
}
