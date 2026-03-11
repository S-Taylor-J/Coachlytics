//
//  TimeInterval+Formatting.swift
//  CoachingManager
//
//  Created by Taylor Santos on 06/01/2026.
//

import Foundation

extension TimeInterval {
    /// Format as MM:SS (e.g., "05:30")
    var formattedMinutesSeconds: String {
        let minutes = Int(self) / 60
        let seconds = Int(self) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    /// Format as H:MM:SS or MM:SS depending on duration
    var formattedDuration: String {
        let hours = Int(self) / 3600
        let minutes = (Int(self) % 3600) / 60
        let seconds = Int(self) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    /// Format for play time display (e.g., "5h 30m" or "30m 45s")
    var formattedPlayTime: String {
        let hours = Int(self) / 3600
        let minutes = (Int(self) % 3600) / 60
        let seconds = Int(self) % 60
        
        if hours > 0 {
            return String(format: "%dh %02dm", hours, minutes)
        } else {
            return String(format: "%dm %02ds", minutes, seconds)
        }
    }
}
