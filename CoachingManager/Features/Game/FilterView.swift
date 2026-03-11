//
//  FilterView.swift
//  CoachingManager
//
//  Created by Taylor Santos on 02/01/2026.
//

import Foundation
import SwiftUI

// MARK: - Filter View
struct FilterView: View {
    @Binding var selectedTeam: TeamType?
    @Binding var selectedEventType: EventType?
    @Binding var selectedCircleResult: CircleResult?
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var hasActiveFilters: Bool {
        selectedTeam != nil || selectedEventType != nil || selectedCircleResult != nil
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Team Filter Menu
                Menu {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { selectedTeam = nil }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        Label("All Teams", systemImage: selectedTeam == nil ? "checkmark" : "list.bullet")
                    }
                    
                    Divider()
                    
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { selectedTeam = .ourTeam }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        Label("Our Team", systemImage: selectedTeam == .ourTeam ? "checkmark" : "house.fill")
                    }
                    
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { selectedTeam = .otherTeam }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        Label("Opponent", systemImage: selectedTeam == .otherTeam ? "checkmark" : "figure.run")
                    }
                } label: {
                    EventFilterChip(
                        label: selectedTeam?.rawValue ?? "All Teams",
                        icon: teamIcon,
                        isActive: selectedTeam != nil,
                        color: teamColor
                    )
                }
                
                // Event Type Filter Menu
                Menu {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { selectedEventType = nil }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        Label("All Events", systemImage: selectedEventType == nil ? "checkmark" : "square.grid.2x2")
                    }
                    
                    Divider()
                    
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { selectedEventType = .infraction }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        Label("Infractions", systemImage: selectedEventType == .infraction ? "checkmark" : "exclamationmark.triangle.fill")
                    }
                    
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { selectedEventType = .goal }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        Label("Goals", systemImage: selectedEventType == .goal ? "checkmark" : "soccerball")
                    }
                    
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { selectedEventType = .circleEntry }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        Label("Circle Entry", systemImage: selectedEventType == .circleEntry ? "checkmark" : "circle.dashed")
                    }
                    
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { selectedEventType = .turnover }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        Label("Turnovers", systemImage: selectedEventType == .turnover ? "checkmark" : "arrow.triangle.2.circlepath")
                    }
                } label: {
                    EventFilterChip(
                        label: selectedEventType?.rawValue ?? "All Events",
                        icon: eventIcon,
                        isActive: selectedEventType != nil,
                        color: eventColor
                    )
                }
                .onChange(of: selectedEventType) { _, newValue in
                    // Clear circle result filter when changing away from circle entry
                    if newValue != .circleEntry {
                        selectedCircleResult = nil
                    }
                }
                
                // Circle Result Filter Menu (only shown when Circle Entry is selected)
                if selectedEventType == .circleEntry {
                    Menu {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) { selectedCircleResult = nil }
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        } label: {
                            Label("All Outcomes", systemImage: selectedCircleResult == nil ? "checkmark" : "list.bullet")
                        }
                        
                        Divider()
                        
                        ForEach(CircleResult.allCases, id: \.self) { result in
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) { selectedCircleResult = result }
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            } label: {
                                Label(result.rawValue, systemImage: selectedCircleResult == result ? "checkmark" : circleResultIcon(for: result))
                            }
                        }
                    } label: {
                        EventFilterChip(
                            label: selectedCircleResult?.rawValue ?? "All Outcomes",
                            icon: circleResultIcon(for: selectedCircleResult),
                            isActive: selectedCircleResult != nil,
                            color: circleResultColor(for: selectedCircleResult)
                        )
                    }
                    .transition(.scale.combined(with: .opacity))
                }
                
                // Clear filters button
                if hasActiveFilters {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTeam = nil
                            selectedEventType = nil
                            selectedCircleResult = nil
                        }
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(Color(.systemGray3))
                    }
                    .buttonStyle(.plain)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Helper Properties
    private var teamIcon: String {
        switch selectedTeam {
        case .ourTeam: return "house.fill"
        case .otherTeam: return "figure.run"
        case nil: return "person.2.fill"
        }
    }
    
    private var teamColor: Color {
        switch selectedTeam {
        case .ourTeam: return .red
        case .otherTeam: return .blue
        case nil: return .gray
        }
    }
    
    private var eventIcon: String {
        switch selectedEventType {
        case .infraction: return "exclamationmark.triangle.fill"
        case .goal: return "soccerball"
        case .circleEntry: return "circle.dashed"
        case .turnover: return "arrow.triangle.2.circlepath"
        case nil: return "square.grid.2x2"
        }
    }
    
    private var eventColor: Color {
        switch selectedEventType {
        case .infraction: return .orange
        case .goal: return .yellow
        case .circleEntry: return .green
        case .turnover: return .red
        case nil: return .gray
        }
    }
    
    private func circleResultIcon(for result: CircleResult?) -> String {
        guard let result = result else { return "circle.dashed" }
        switch result {
        case .goal: return "soccerball"
        case .penaltyCorner: return "flag.fill"
        case .shotSaved: return "hand.raised.fill"
        case .shotWide: return "arrow.up.right"
        case .turnover: return "arrow.triangle.2.circlepath"
        case .longCorner: return "flag.2.crossed.fill"
        case .nothing: return "circle.dashed"
        }
    }
    
    private func circleResultColor(for result: CircleResult?) -> Color {
        guard let result = result else { return .gray }
        let settings = CircleResultSettings.loadFromDefaults()
        return settings.appearance(for: result).color
    }
}

// MARK: - Event Filter Chip (matches GameListView's FilterChip style)
struct EventFilterChip: View {
    let label: String
    let icon: String
    let isActive: Bool
    let color: Color
    
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .medium))
            
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .lineLimit(1)
            
            Image(systemName: "chevron.down")
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(isActive ? .white.opacity(0.7) : .secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(isActive ? color : Color(.systemGray5))
        )
        .foregroundColor(isActive ? .white : .primary)
        .overlay(
            Capsule()
                .strokeBorder(Color(.systemGray4).opacity(isActive ? 0 : 0.5), lineWidth: 0.5)
        )
    }
}

// MARK: - Legacy Filter Pill (kept for backward compatibility)
struct FilterPill: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                
                Text(title)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? color : Color(.systemGray5))
                    .shadow(
                        color: isSelected ? color.opacity(0.3) : Color.clear,
                        radius: 4,
                        x: 0,
                        y: 2
                    )
            )
            .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isSelected)
    }
}

// MARK: - Preview
#Preview {
    FilterView(selectedTeam: .constant(nil), selectedEventType: .constant(nil), selectedCircleResult: .constant(nil))
}
