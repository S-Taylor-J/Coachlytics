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
    /// Position in **unit space**: `x` and `y` are 0...1, relative to the pitch rect.
    /// Stored normalized so a formation survives the pitch resizing — expanding the bench,
    /// rotating, or moving between iPhone and iPad. Converted to points at render time.
    var position: CGPoint
    var timeOnPitch: TimeInterval = 0
    
    static func == (lhs: PitchPlayer, rhs: PitchPlayer) -> Bool {
        lhs.id == rhs.id && lhs.player.id == rhs.player.id && lhs.position == rhs.position
    }
}
