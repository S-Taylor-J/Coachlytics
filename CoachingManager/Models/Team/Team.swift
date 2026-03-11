//
//  Teams.swift
//  CoachingManager
//
//  Created by Taylor Santos on 06/01/2026.
//

import SwiftUI
import SwiftData

@Model
class Team {
    var id: UUID
    var name: String
    @Relationship(deleteRule: .cascade) var players: [Player] = []
    
    init(name: String) {
        self.id = UUID()
        self.name = name
    }
}

