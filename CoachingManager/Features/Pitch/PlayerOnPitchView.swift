//
//  PlayerOnPitchView.swift
//  CoachingManager
//
//  Created by Taylor Santos on 06/01/2026.
//

import SwiftUI

struct PlayerOnPitchView: View {
    let player: Player
    @Binding var position: CGPoint
    let pitchSize: CGSize
    let quarterPlayPercentage: Double // 0.0 to 1.0
    let playTime: TimeInterval // Time played in seconds
    var isCompact: Bool = false // True for iPhone, false for iPad
    var onRemove: (() -> Void)? = nil
    var onTap: (() -> Void)? = nil
    
    // Format time as MM:SS
    private var formattedPlayTime: String {
        let minutes = Int(playTime) / 60
        let seconds = Int(playTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    @State private var lastPosition: CGPoint = .zero
    @State private var dragStartTime: Date? = nil
    @State private var isDragging = false
    @State private var isOverBench = false
    @State private var dragOffset: CGSize = .zero
    @State private var dragScale: CGFloat = 1.0
    @State private var shadowRadius: CGFloat = 4
    @State private var shadowOpacity: Double = 0.3
    @State private var glowOpacity: Double = 0
    @State private var rotationAngle: Double = 0
    @State private var isPressed = false
    @State private var showSwapHint = false
    
    // Size multiplier based on device
    private var sizeMultiplier: CGFloat { isCompact ? 0.7 : 1.0 }
    
    // Computed sizes
    private var circleSize: CGFloat { 44 * sizeMultiplier }
    private var glowSize: CGFloat { 56 * sizeMultiplier }
    private var numberFontSize: CGFloat { 16 * sizeMultiplier }
    private var trashIconSize: CGFloat { 16 * sizeMultiplier }
    private var nameFontSize: CGFloat { 10 * sizeMultiplier }
    private var swapIconSize: CGFloat { 14 * sizeMultiplier }
//    private var progressBarWidth: CGFloat { 40 * sizeMultiplier }
    private var edgeMargin: CGFloat { isCompact ? 18 : 25 }
    
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
    
    // Premium gradient for player
    private var playerGradient: LinearGradient {
        LinearGradient(
            colors: isDragging 
                ? (isOverBench 
                    ? [Color.red.opacity(0.9), Color.red, Color.red.opacity(0.85)]
                    : [Color.blue.opacity(0.95), Color.blue, Color.blue.opacity(0.9)])
                : [Color.blue.opacity(0.9), Color.blue, Color.blue.opacity(0.85)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // Remove indicator gradient
    private var removeGradient: LinearGradient {
        LinearGradient(
            colors: [Color.red.opacity(0.9), Color.red],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var firstNamePlusInitial: String {
        let parts = player.name.split(separator: " ")
        let first = parts.first.map(String.init) ?? ""
        let lastInitial = parts.count > 1 ? String(parts.last!.prefix(1)) : ""
        return lastInitial.isEmpty ? first : first + " " + lastInitial
    }
    
    var body: some View {
        VStack(spacing: isCompact ? 2 : 3) {
            ZStack {
                let ambientGlowColor: Color = isOverBench ? Color.red.opacity(0.5) : Color.blue.opacity(0.4)
                let shadowColor: Color = (isOverBench ? Color.red : Color.blue).opacity(shadowOpacity)
                let mainGradient: LinearGradient = playerGradient
                
                // Ambient glow effect
                Circle()
                    .fill(ambientGlowColor)
                    .frame(width: glowSize, height: glowSize)
                    .blur(radius: 12)
                    .opacity(glowOpacity)
                
                // Shadow base
                Circle()
                    .fill(Color.black.opacity(0.15))
                    .frame(width: circleSize, height: circleSize)
                    .offset(y: isDragging ? 12 : 4)
                    .blur(radius: isDragging ? 8 : 4)
                    .scaleEffect(isDragging ? 0.9 : 1.0)
                
                // Main player circle
                Circle()
                    .fill(mainGradient)
                    .frame(width: circleSize, height: circleSize)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: isPressed 
                                        ? [Color.white.opacity(0.8), Color.white.opacity(0.5)]
                                        : [Color.white.opacity(0.5), Color.white.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: isPressed ? 2.5 : 1.5
                            )
                    )
                    .overlay(
                        overlayContent
                            .animation(.easeInOut(duration: 0.15), value: isOverBench)
                    )
                    .overlay(alignment: .bottomTrailing) {
                        // Swap icon badge - indicates tap for substitution
                        if !isDragging && onTap != nil {
                            ZStack {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: swapIconSize + 4, height: swapIconSize + 4)
                                
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .font(.system(size: swapIconSize * 0.7, weight: .bold))
                                    .foregroundColor(.blue)
                            }
                            .offset(x: 2, y: 2)
                            .scaleEffect(showSwapHint ? 1.15 : 1.0)
                            .animation(
                                showSwapHint 
                                    ? .easeInOut(duration: 0.6).repeatForever(autoreverses: true)
                                    : .default,
                                value: showSwapHint
                            )
                        }
                    }
                    .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: isDragging ? 8 : 3)
                    .scaleEffect(isPressed ? 0.95 : 1.0)
                    .animation(.easeOut(duration: 0.1), value: isPressed)
            }
            .scaleEffect(dragScale)
            .rotationEffect(.degrees(rotationAngle))
            
            // Player name label with time
            VStack(spacing: 1) {
                Text(firstNamePlusInitial)
                    .font(.system(size: nameFontSize, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                
                // Time display
                HStack(spacing: 2) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: isCompact ? 6 : 8))
                    Text(formattedPlayTime)
                        .font(.system(size: isCompact ? 7 : 9, weight: .medium, design: .monospaced))
                }
                .foregroundColor(.white.opacity(0.85))
            }
            .padding(.horizontal, isCompact ? 4 : 8)
            .padding(.vertical, isCompact ? 3 : 4)
            .background(
                Capsule()
                    .fill(
                        isDragging 
                            ? (isOverBench ? Color.red.opacity(0.9) : Color.black.opacity(0.85))
                            : Color.black.opacity(0.7)
                    )
            )
            .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
            .scaleEffect(isDragging ? 1.05 : 1.0)
            
            // Quarter play percentage bar
//            ZStack(alignment: .leading) {
//                // Background track
//                RoundedRectangle(cornerRadius: 2)
//                    .fill(Color.black.opacity(0.4))
//                    .frame(width: progressBarWidth, height: isCompact ? 3 : 4)
//                
//                // Progress fill
//                RoundedRectangle(cornerRadius: 2)
//                    .fill(progressColor)
//                    .frame(width: progressBarWidth * CGFloat(min(quarterPlayPercentage, 1.0)), height: isCompact ? 3 : 4)
//            }
//            .shadow(color: Color.black.opacity(0.3), radius: 1, x: 0, y: 1)
        }
        .offset(dragOffset)
        .position(position)
        .zIndex(isDragging ? 100 : 0) // Bring to front when dragging
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    if !isDragging {
                        // Record start time to detect taps
                        dragStartTime = Date()
                        isPressed = true
                        // Start dragging
                        lastPosition = position
                        startDragAnimation()
                        
                        // Haptic feedback
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                    }
                    
                    // Smooth drag offset with slight dampening
                    withAnimation(.interactiveSpring(response: 0.15, dampingFraction: 0.8)) {
                        dragOffset = value.translation
                    }
                    
                    // Check bench proximity
                    let currentX = position.x + value.translation.width
                    let wasOverBench = isOverBench
                    isOverBench = currentX < 20
                    
                    // Haptic when crossing bench threshold
                    if wasOverBench != isOverBench {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
                            if isOverBench {
                                rotationAngle = -5
                            } else {
                                rotationAngle = 0
                            }
                        }
                    }
                    
                    // Velocity-based rotation for dynamic feel
                    let velocityX = value.velocity.width / 1000
                    withAnimation(.interactiveSpring(response: 0.1, dampingFraction: 0.5)) {
                        rotationAngle = isOverBench ? -5 : min(max(velocityX * 2, -3), 3)
                    }
                }
                .onEnded { value in
                    let newX = lastPosition.x + value.translation.width
                    let newY = lastPosition.y + value.translation.height
                    
                    if isOverBench {
                        // Remove with satisfying animation
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                        
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            dragScale = 0.1
                            glowOpacity = 0
                            shadowOpacity = 0
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            onRemove?()
                        }
                    } else {
                        // Apply momentum-based final position
                        let velocityFactor: CGFloat = 0.08
                        let projectedX = newX + (value.velocity.width * velocityFactor)
                        let projectedY = newY + (value.velocity.height * velocityFactor)
                        
                        let constrainedX = min(max(edgeMargin, projectedX), pitchSize.width - edgeMargin)
                        let constrainedY = min(max(edgeMargin, projectedY), pitchSize.height - edgeMargin)
                        
                        // Spring animation for satisfying drop
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.65, blendDuration: 0)) {
                            position = CGPoint(x: constrainedX, y: constrainedY)
                            dragOffset = .zero
                            rotationAngle = 0
                        }
                        
                        // End drag animation
                        endDragAnimation()
                        
                        // Soft haptic on drop
                        let generator = UIImpactFeedbackGenerator(style: .soft)
                        generator.impactOccurred()
                    }
                    
                    isDragging = false
                    isOverBench = false
                    isPressed = false
                    
                    // Detect tap (short duration, minimal movement)
                    if let startTime = dragStartTime {
                        let duration = Date().timeIntervalSince(startTime)
                        let totalMovement = abs(value.translation.width) + abs(value.translation.height)
                        if duration < 0.2 && totalMovement < 10 {
                            // Provide haptic feedback for tap
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            onTap?()
                        }
                    }
                    dragStartTime = nil
                }
        )
        .onAppear {
            lastPosition = position
            // Show swap hint animation briefly when player first appears
            if onTap != nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showSwapHint = true
                    // Stop the hint animation after a few seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        showSwapHint = false
                    }
                }
            }
        }
    }
    
    // MARK: - Animation Helpers
    
    private func startDragAnimation() {
        isDragging = true
        withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
            dragScale = 1.15
            shadowRadius = 16
            shadowOpacity = 0.5
            glowOpacity = 0.8
        }
    }
    
    private func endDragAnimation() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            dragScale = 1.0
            shadowRadius = 4
            shadowOpacity = 0.3
            glowOpacity = 0
        }
    }
    
    @ViewBuilder
    private var overlayContent: some View {
        if !(isDragging && isOverBench) {
            Text("\(player.number)")
                .font(.system(size: numberFontSize, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .transition(.opacity.combined(with: .scale))
        } else {
            Image(systemName: "trash.fill")
                .font(.system(size: trashIconSize, weight: .semibold))
                .foregroundColor(.white)
                .transition(.opacity.combined(with: .scale))
        }
    }
}
