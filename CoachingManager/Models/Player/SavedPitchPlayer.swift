//
//  SavedPitchPlayer.swift
//  CoachingManager
//
//  Created by Taylor Santos on 06/01/2026.
//

import SwiftUI

struct SavedPitchPlayer: Codable {
    let id: UUID
    let playerId: UUID
    let x: CGFloat
    let y: CGFloat
    let timeOnPitch: TimeInterval
}
