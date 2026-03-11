//
//  PitchMarkingsShape.swift
//  CoachingManager
//
//  Created by Taylor Santos on 06/01/2026.
//

import SwiftUI

struct HockeyPitch: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        // Slightly rounded corners for modern look
        path.addRoundedRect(
            in: rect,
            cornerSize: CGSize(width: 8, height: 8)
        )
        return path
    }
}

struct PitchMarkings: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        let inset: CGFloat = 2 // Small inset from edges
        
        // Center line
        path.move(to: CGPoint(x: inset, y: height / 2))
        path.addLine(to: CGPoint(x: width - inset, y: height / 2))
        
        // Center circle
        let center = CGPoint(x: width / 2, y: height / 2)
        let centerRadius = width * 0.08
        path.addEllipse(
            in: CGRect(
                x: center.x - centerRadius,
                y: center.y - centerRadius,
                width: centerRadius * 2,
                height: centerRadius * 2
            )
        )
        
        // Center dot
        let dotRadius: CGFloat = 4
        path.addEllipse(
            in: CGRect(
                x: center.x - dotRadius,
                y: center.y - dotRadius,
                width: dotRadius * 2,
                height: dotRadius * 2
            )
        )
        
        // 23m lines (defensive zones)
        let offset = height * 0.23
        path.move(to: CGPoint(x: inset, y: offset))
        path.addLine(to: CGPoint(x: width - inset, y: offset))
        
        path.move(to: CGPoint(x: inset, y: height - offset))
        path.addLine(to: CGPoint(x: width - inset, y: height - offset))
        
        // Shooting circles (Ds) - more refined
        let radius = width * 0.18
        
        // Top D
        let topD = CGPoint(x: width / 2, y: 0)
        path.move(to: CGPoint(x: topD.x - radius, y: topD.y + inset))
        path.addArc(
            center: CGPoint(x: topD.x, y: topD.y + inset),
            radius: radius,
            startAngle: .degrees(180),
            endAngle: .degrees(0),
            clockwise: true
        )
        
        // Bottom D
        let bottomD = CGPoint(x: width / 2, y: height)
        path.move(to: CGPoint(x: bottomD.x - radius, y: bottomD.y - inset))
        path.addArc(
            center: CGPoint(x: bottomD.x, y: bottomD.y - inset),
            radius: radius,
            startAngle: .degrees(180),
            endAngle: .degrees(0),
            clockwise: false
        )
        
        // Goals - more visible
        let goalWidth = width * 0.12
        let goalHeight = height * 0.025
        
        // Top goal
        path.addRoundedRect(
            in: CGRect(
                x: (width - goalWidth) / 2,
                y: 0,
                width: goalWidth,
                height: goalHeight
            ),
            cornerSize: CGSize(width: 2, height: 2)
        )
        
        // Bottom goal
        path.addRoundedRect(
            in: CGRect(
                x: (width - goalWidth) / 2,
                y: height - goalHeight,
                width: goalWidth,
                height: goalHeight
            ),
            cornerSize: CGSize(width: 2, height: 2)
        )
        
        // Penalty spots
        let penaltySpotRadius: CGFloat = 3
        let penaltySpotOffset = height * 0.12
        
        // Top penalty spot
        path.addEllipse(
            in: CGRect(
                x: width / 2 - penaltySpotRadius,
                y: penaltySpotOffset - penaltySpotRadius,
                width: penaltySpotRadius * 2,
                height: penaltySpotRadius * 2
            )
        )
        
        // Bottom penalty spot
        path.addEllipse(
            in: CGRect(
                x: width / 2 - penaltySpotRadius,
                y: height - penaltySpotOffset - penaltySpotRadius,
                width: penaltySpotRadius * 2,
                height: penaltySpotRadius * 2
            )
        )
        
        return path
    }
}
