//
//  Player.swift
//  CoachingManager
//
//  Created by Taylor Santos on 06/01/2026.
//

import Foundation
import SwiftUI
import SwiftData

@Model
class Player {
    var id: UUID
    var name: String
    var number: Int
    var positions: [String]
    var skills: [String]
    @Relationship(inverse: \Team.players) var teams: [Team] = []
    
    init(name: String, number: Int, positions: [String] = [], skills: [String] = []) {
        self.id = UUID()
        self.name = name
        self.number = number
        self.positions = positions
        self.skills = skills
    }
}
