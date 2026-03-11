//
//  NotificationBannerView.swift
//  CoachingManager
//
//  Created by Taylor Santos on 06/01/2026.
//

import SwiftUI

// MARK: - Notification Type
/// Types of notification banners
enum NotificationType {
    case warning
    case error
    case info
    case success
    
    var color: Color {
        switch self {
        case .warning: return .orange
        case .error: return .red
        case .info: return .blue
        case .success: return .green
        }
    }
    
    var icon: String {
        switch self {
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.circle.fill"
        case .info: return "info.circle.fill"
        case .success: return "checkmark.circle.fill"
        }
    }
}

// MARK: - Notification Banner
/// A collapsible notification banner
struct NotificationBanner: View {
    let message: String
    let type: NotificationType
    var onDismiss: (() -> Void)? = nil
    
    @State private var isExpanded = true
    @State private var collapseTask: Task<Void, Never>? = nil
    
    // Timing constants
    private let initialDisplayDuration: Double = 4.0
    private let reExpandDisplayDuration: Double = 5.0
    
    var body: some View {
        Group {
            if isExpanded {
                expandedView
            } else {
                collapsedView
            }
        }
        .onAppear {
            scheduleCollapse(after: initialDisplayDuration)
        }
        .onDisappear {
            collapseTask?.cancel()
        }
    }
    
    // MARK: - Expanded View
    private var expandedView: some View {
        HStack(spacing: 10) {
            Image(systemName: type.icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            Text(message)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer(minLength: 8)
            
            // Close button
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded = false
                }
                collapseTask?.cancel()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(6)
                    .background(Circle().fill(Color.white.opacity(0.2)))
            }
        }
        .padding(.leading, 14)
        .padding(.trailing, 10)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(type.color.gradient)
                .shadow(color: type.color.opacity(0.4), radius: 8, x: 0, y: 4)
        )
        .frame(maxWidth: 300)
        .transition(
            .asymmetric(
                insertion: .scale(scale: 0.9).combined(with: .opacity),
                removal: .scale(scale: 0.9).combined(with: .opacity)
            )
        )
    }
    
    // MARK: - Collapsed View (Icon Only)
    private var collapsedView: some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                isExpanded = true
            }
            scheduleCollapse(after: reExpandDisplayDuration)
        } label: {
            ZStack {
                Circle()
                    .fill(type.color.gradient)
                    .frame(width: 44, height: 44)
                    .shadow(color: type.color.opacity(0.4), radius: 6, x: 0, y: 3)
                
                Image(systemName: type.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(.plain)
        .transition(
            .asymmetric(
                insertion: .scale(scale: 0.5).combined(with: .opacity),
                removal: .scale(scale: 0.5).combined(with: .opacity)
            )
        )
    }
    
    // MARK: - Collapse Timer
    private func scheduleCollapse(after seconds: Double) {
        collapseTask?.cancel()
        collapseTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            if !Task.isCancelled {
                await MainActor.run {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        isExpanded = false
                    }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color(.systemGray6)
            .ignoresSafeArea()
        
        VStack(spacing: 20) {
            NotificationBanner(
                message: "Player doesn't have required skills",
                type: .warning
            )
            
            NotificationBanner(
                message: "Error saving formation",
                type: .error
            )
            
            NotificationBanner(
                message: "Formation saved successfully",
                type: .info
            )
        }
        .padding()
    }
}
