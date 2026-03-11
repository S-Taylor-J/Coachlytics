//
//  CalendarEvent.swift
//  CoachingManager
//
//  Created by Taylor Santos on 06/01/2026.
//

import Foundation

/// Types of calendar events
enum CalendarEventType {
    case game
    case training
    case note
}

/// A calendar event (game, training, or note)
struct CalendarEvent: Identifiable {
    let id: UUID
    let date: Date
    let title: String
    let type: CalendarEventType
    
    init(id: UUID = UUID(), date: Date, title: String, type: CalendarEventType) {
        self.id = id
        self.date = date
        self.title = title
        self.type = type
    }
}
