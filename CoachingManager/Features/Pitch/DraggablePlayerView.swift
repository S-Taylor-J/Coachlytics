//
//  DraggablePlayerView.swift
//  CoachingManager
//
//  Created by Taylor Santos on 06/01/2026.
//

import SwiftUI
import UniformTypeIdentifiers

struct DraggablePlayerView: View {
    let player: Player
    let quarterPlayPercentage: Double // 0.0 to 1.0
    let playTime: TimeInterval // Time played in seconds
    var isCompact: Bool = false // True for iPhone, false for iPad
    
    // Format time as MM:SS
    private var formattedPlayTime: String {
        let minutes = Int(playTime) / 60
        let seconds = Int(playTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    @State private var isDragging = false
    @State private var dragScale: CGFloat = 1.0
    @State private var shadowRadius: CGFloat = 2
    @State private var isPressed = false
    
    // Size multiplier based on device
    private var sizeMultiplier: CGFloat { isCompact ? 0.7 : 1.0 }
    
    // Computed sizes
    private var circleSize: CGFloat { 44 * sizeMultiplier }
    private var glowSize: CGFloat { 48 * sizeMultiplier }
    private var numberFontSize: CGFloat { 16 * sizeMultiplier }
    private var nameFontSize: CGFloat { 11 * sizeMultiplier }
//    private var progressBarWidth: CGFloat { 50 * sizeMultiplier }
//    private var percentFontSize: CGFloat { 8 * sizeMultiplier }
    
    // Premium color gradient for player circle
    private var playerGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.blue.opacity(0.9),
                Color.blue,
                Color.blue.opacity(0.85)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // Color based on play percentage
    private var progressColor: Color {
        if quarterPlayPercentage >= 0.75 {
            return .green
        } else if quarterPlayPercentage >= 0.5 {
            return .yellow
        } else if quarterPlayPercentage >= 0.25 {
            return .orange
        } else {
            return .red
        }
    }
    
    var body: some View {
        VStack(spacing: isCompact ? 2 : 4) {
            // Player Circle with premium styling
            ZStack {
                // Outer glow when dragging
                Circle()
                    .fill(Color.blue.opacity(0.3))
                    .frame(width: glowSize, height: glowSize)
                    .blur(radius: isDragging ? 8 : 0)
                    .opacity(isDragging ? 1 : 0)
                
                // Main circle
                Circle()
                    .fill(playerGradient)
                    .frame(width: circleSize, height: circleSize)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                    .overlay(
                        Text("\(player.number)")
                            .font(.system(size: numberFontSize, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    )
                    .shadow(color: Color.blue.opacity(isDragging ? 0.5 : 0.2), radius: shadowRadius, x: 0, y: isDragging ? 8 : 2)
            }
            
            // Player name with premium styling
            Text(player.name.split(separator: " ").last ?? "")
                .font(.system(size: nameFontSize, weight: .medium, design: .rounded))
                .foregroundColor(.primary.opacity(0.8))
                .lineLimit(1)
            
            // Time display
            HStack(spacing: 3) {
                Image(systemName: "clock.fill")
                    .font(.system(size: isCompact ? 8 : 10))
                    .foregroundColor(.secondary)
                Text(formattedPlayTime)
                    .font(.system(size: isCompact ? 9 : 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            
            // Quarter play percentage bar
//            VStack(spacing: 2) {
//                GeometryReader { geo in
//                    ZStack(alignment: .leading) {
//                        // Background track
//                        RoundedRectangle(cornerRadius: 2)
//                            .fill(Color(.systemGray4))
//                            .frame(height: isCompact ? 3 : 4)
//                        
//                        // Progress fill
//                        RoundedRectangle(cornerRadius: 2)
//                            .fill(progressColor)
//                            .frame(width: geo.size.width * CGFloat(min(quarterPlayPercentage, 1.0)), height: isCompact ? 3 : 4)
//                    }
//                }
//                .frame(height: isCompact ? 3 : 4)
//                
//                Text("\(Int(quarterPlayPercentage * 100))%")
//                    .font(.system(size: percentFontSize, weight: .semibold, design: .rounded))
//                    .foregroundColor(.secondary)
//            }
//            .frame(width: progressBarWidth)
        }
        .padding(.horizontal, isCompact ? 6 : 10)
        .padding(.vertical, isCompact ? 5 : 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(isPressed ? 0.15 : 0.08), radius: isPressed ? 2 : 4, x: 0, y: isPressed ? 1 : 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.blue.opacity(isDragging ? 0.5 : 0), lineWidth: 2)
        )
        .scaleEffect(dragScale)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: dragScale)
        .animation(.easeInOut(duration: 0.2), value: isDragging)
        .onLongPressGesture(minimumDuration: 0.1, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.15)) {
                isPressed = pressing
                if pressing {
                    dragScale = 0.95
                } else {
                    dragScale = 1.0
                }
            }
        }, perform: {})
        .draggable(player.id.uuidString) {
            // Custom drag preview
            DragPreviewView(player: player)
                .onAppear {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
                        isDragging = true
                        dragScale = 1.05
                        shadowRadius = 12
                    }
                    // Haptic feedback
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                }
        }
        .onChange(of: isDragging) { _, newValue in
            if !newValue {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    dragScale = 1.0
                    shadowRadius = 2
                }
            }
        }
    }
}

// MARK: - Premium Drag Preview
struct DragPreviewView: View {
    let player: Player
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                // Glow effect
                Circle()
                    .fill(Color.blue.opacity(0.4))
                    .frame(width: 56, height: 56)
                    .blur(radius: 10)
                
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.95), Color.blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.4), lineWidth: 2)
                    )
                    .overlay(
                        Text("\(player.number)")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    )
                    .shadow(color: Color.blue.opacity(0.6), radius: 12, x: 0, y: 8)
            }
            
            Text(player.name.split(separator: " ").last ?? "")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.7))
                )
        }
        .padding(8)
    }
}

