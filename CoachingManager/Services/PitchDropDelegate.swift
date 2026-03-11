//
//  PitchDropDelegate.swift
//  CoachingManager
//
//  Created by Taylor Santos on 06/01/2026.
//

import SwiftUI
import UniformTypeIdentifiers

struct PitchDropDelegate: DropDelegate {
    let players: [Player]
    @Binding var pitchPlayers: [PitchPlayer]
    let pitchSize: CGSize
    @Binding var isTargeted: Bool
    @Binding var dropLocation: CGPoint?
    
    func validateDrop(info: DropInfo) -> Bool {
        info.hasItemsConforming(to: [UTType.text])
    }
    
    func dropEntered(info: DropInfo) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            isTargeted = true
            dropLocation = info.location
        }
        
        // Haptic feedback on enter
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        // Update drop location for visual feedback
        withAnimation(.interactiveSpring(response: 0.1, dampingFraction: 0.8)) {
            dropLocation = info.location
        }
        return DropProposal(operation: .copy)
    }
    
    func dropExited(info: DropInfo) {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
            isTargeted = false
            dropLocation = nil
        }
    }
    
    func performDrop(info: DropInfo) -> Bool {
        guard let item = info.itemProviders(for: [UTType.text]).first else {
            resetDropState()
            return false
        }
        
        let location = info.location
        
        item.loadObject(ofClass: NSString.self) { data, _ in
            guard
                let idString = data as? String,
                let id = UUID(uuidString: idString),
                let player = players.first(where: { $0.id == id }),
                !pitchPlayers.contains(where: { $0.player.id == id })
            else {
                DispatchQueue.main.async {
                    resetDropState()
                }
                return
            }
            
            DispatchQueue.main.async {
                // Calculate constrained position
                let constrainedX = min(max(30, location.x), pitchSize.width - 30)
                let constrainedY = min(max(30, location.y), pitchSize.height - 30)
                
                // Success haptic
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                
                // Add player with animation
                withAnimation(.spring(response: 0.4, dampingFraction: 0.65)) {
                    pitchPlayers.append(
                        PitchPlayer(
                            id: UUID(),
                            player: player,
                            position: CGPoint(x: constrainedX, y: constrainedY)
                        )
                    )
                }
                
                // Reset drop state
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isTargeted = false
                    dropLocation = nil
                }
            }
        }
        
        return true
    }
    
    private func resetDropState() {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
            isTargeted = false
            dropLocation = nil
        }
    }
}

// MARK: - Drop Zone Visual Indicator
struct DropZoneIndicator: View {
    let isTargeted: Bool
    let dropLocation: CGPoint?
    let pitchSize: CGSize
    
    var body: some View {
        ZStack {
            // Full pitch highlight when targeted
            if isTargeted {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.blue.opacity(0.6), lineWidth: 3)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue.opacity(0.08))
                    )
                    .animation(.easeInOut(duration: 0.2), value: isTargeted)
            }
            
            // Drop location indicator
            if let location = dropLocation {
                ZStack {
                    // Outer pulse ring
                    Circle()
                        .stroke(Color.blue.opacity(0.3), lineWidth: 2)
                        .frame(width: 60, height: 60)
                        .scaleEffect(isTargeted ? 1.2 : 0.8)
                        .opacity(isTargeted ? 0.6 : 0)
                    
                    // Inner indicator
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Circle()
                        .stroke(Color.blue.opacity(0.8), lineWidth: 2)
                        .frame(width: 50, height: 50)
                    
                    // Center dot
                    Circle()
                        .fill(Color.blue.opacity(0.6))
                        .frame(width: 8, height: 8)
                    
                    // Plus icon
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.blue.opacity(0.8))
                        .offset(y: -20)
                }
                .position(location)
                .animation(.spring(response: 0.2, dampingFraction: 0.7), value: location)
            }
        }
        .allowsHitTesting(false) // Don't interfere with drops
    }
}
