//
//  PitchPlayer.swift
//  CoachingManager
//
//  Created by Taylor Santos on 06/01/2026.
//

import SwiftData
import Foundation
internal import CoreGraphics

struct PitchPlayer: Identifiable, Equatable {
    let id: UUID
    let player: Player
    var position: CGPoint
    var timeOnPitch: TimeInterval = 0
    
    static func == (lhs: PitchPlayer, rhs: PitchPlayer) -> Bool {
        lhs.id == rhs.id && lhs.player.id == rhs.player.id && lhs.position == rhs.position
    }
}
