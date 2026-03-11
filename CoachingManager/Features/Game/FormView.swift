//
//  FormView.swift
//  CoachingManager
//
//  Created by Taylor Santos on 06/01/2026.
//

import Foundation
import SwiftUI

// MARK: - Multi Step Form View
struct MultiStepFormView: View {
    @Binding var currentStep: Int
    @Binding var selectedEventType: EventType
    @Binding var selectedTeam: TeamType
    @Binding var selectedPlayerId: UUID?
    @Binding var selectedInfraction: InfractionType
    @Binding var selectedCardType: CardType
    @Binding var selectedCircleResult: CircleResult
    @Binding var selectedGoalType: GoalType
    let players: [Player]
    let requirePlayerForInfractions: Bool
    let requirePlayerForCircleEntry: Bool
    let requirePlayerForTurnover: Bool
    let onSave: () -> Void
    let onCancel: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress indicator
                progressBar
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                
                // Form content based on current step
                ScrollView(showsIndicators: false) {
                    Group {
                        switch currentStep {
                        case 0:
                            EventTypeStep(
                                selectedEventType: $selectedEventType,
                                onNext: goToNextStep
                            )
                        case 1:
                            TeamSelectionStep(
                                selectedTeam: $selectedTeam,
                                onNext: goToNextStep
                            )
                        case 2:
                            // Step 2 depends on event type
                            if selectedEventType == .infraction {
                                if requirePlayerForInfractions && selectedTeam == .ourTeam {
                                    PlayerSelectionWithSkipStep(
                                        selectedPlayerId: $selectedPlayerId,
                                        players: players,
                                        onNext: goToNextStep
                                    )
                                } else {
                                    InfractionDetailsStep(
                                        selectedInfraction: $selectedInfraction,
                                        selectedCardType: $selectedCardType,
                                        onSave: {
                                            onSave()
                                            dismiss()
                                        }
                                    )
                                }
                            } else if selectedEventType == .circleEntry {
                                if requirePlayerForCircleEntry && selectedTeam == .ourTeam {
                                    PlayerSelectionWithSkipStep(
                                        selectedPlayerId: $selectedPlayerId,
                                        players: players,
                                        onNext: goToNextStep
                                    )
                                } else {
                                    CircleResultStep(
                                        selectedCircleResult: $selectedCircleResult,
                                        onSave: {
                                            onSave()
                                            dismiss()
                                        }
                                    )
                                }
                            } else if selectedEventType == .goal {
                                if selectedTeam == .ourTeam {
                                    PlayerSelectionWithSkipStep(
                                        selectedPlayerId: $selectedPlayerId,
                                        players: players,
                                        onNext: goToNextStep
                                    )
                                } else {
                                    GoalTypeStep(
                                        selectedGoalType: $selectedGoalType,
                                        onNext: goToNextStep
                                    )
                                }
                            } else if selectedEventType == .turnover {
                                // Turnover: after team selection, optionally select player for our team
                                if requirePlayerForTurnover && selectedTeam == .ourTeam {
                                    PlayerSelectionWithSkipStep(
                                        selectedPlayerId: $selectedPlayerId,
                                        players: players,
                                        onNext: {
                                            onSave()
                                            dismiss()
                                        }
                                    )
                                } else {
                                    TurnoverConfirmStep(onSave: {
                                        onSave()
                                        dismiss()
                                    })
                                }
                            }
                        case 3:
                            if selectedEventType == .infraction && requirePlayerForInfractions && selectedTeam == .ourTeam {
                                InfractionDetailsStep(
                                    selectedInfraction: $selectedInfraction,
                                    selectedCardType: $selectedCardType,
                                    onSave: {
                                        onSave()
                                        dismiss()
                                    }
                                )
                            } else if selectedEventType == .circleEntry && requirePlayerForCircleEntry && selectedTeam == .ourTeam {
                                CircleResultStep(
                                    selectedCircleResult: $selectedCircleResult,
                                    onSave: {
                                        onSave()
                                        dismiss()
                                    }
                                )
                            } else if selectedEventType == .goal {
                                if selectedTeam == .ourTeam {
                                    GoalTypeStep(
                                        selectedGoalType: $selectedGoalType,
                                        onNext: goToNextStep
                                    )
                                } else {
                                    GoalConfirmStep(
                                        selectedGoalType: selectedGoalType,
                                        onSave: {
                                            onSave()
                                            dismiss()
                                        }
                                    )
                                }
                            }
                        case 4:
                            // Final step for goals with player selection
                            if selectedEventType == .goal && selectedTeam == .ourTeam {
                                GoalConfirmStep(
                                    selectedGoalType: selectedGoalType,
                                    onSave: {
                                        onSave()
                                        dismiss()
                                    }
                                )
                            }
                        default:
                            EmptyView()
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                // Back button
                if currentStep > 0 && currentStep < getTotalSteps() {
                    backButton
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                }
            }
            .background(backgroundGradient.ignoresSafeArea())
            .navigationTitle(getStepTitle())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        onCancel()
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
            }
        }
    }
    
    // MARK: - Background
    private var backgroundGradient: some View {
        LinearGradient(
            colors: colorScheme == .dark
                ? [Color(.systemBackground), Color(.systemGray6)]
                : [Color(.systemGray6).opacity(0.3), Color(.systemBackground)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    // MARK: - Progress Bar
    private var progressBar: some View {
        HStack(spacing: 4) {
            ForEach(0..<getTotalSteps(), id: \.self) { step in
                Capsule()
                    .fill(step <= currentStep ? Color.blue : Color(.systemGray4))
                    .frame(height: 4)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentStep)
            }
        }
    }
    
    // MARK: - Back Button
    private var backButton: some View {
        Button {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                currentStep -= 1
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                Text("Back")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
            }
            .foregroundColor(.secondary)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
        }
    }
    
    private func goToNextStep() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            currentStep += 1
        }
    }
    
    private func getTotalSteps() -> Int {
        switch selectedEventType {
        case .circleEntry:
            if requirePlayerForCircleEntry && selectedTeam == .ourTeam {
                return 4 // Event Type → Team → Player → Outcome
            } else {
                return 3 // Event Type → Team → Outcome
            }
        case .infraction:
            if requirePlayerForInfractions && selectedTeam == .ourTeam {
                return 4 // Event Type → Team → Player → Infraction Details
            } else {
                return 3 // Event Type → Team → Infraction Details
            }
        case .turnover:
            if requirePlayerForTurnover && selectedTeam == .ourTeam {
                return 3 // Event Type → Team → Player (Save)
            } else {
                return 3 // Event Type → Team → Confirm
            }
        case .goal:
            if selectedTeam == .ourTeam {
                return 5 // Event Type → Team → Player → Goal Type → Confirm
            } else {
                return 4 // Event Type → Team → Goal Type → Confirm
            }
        }
    }
    
    private func getStepTitle() -> String {
        switch currentStep {
        case 0: return "Event Type"
        case 1: return "Select Team"
        case 2:
            switch selectedEventType {
            case .circleEntry:
                if requirePlayerForCircleEntry && selectedTeam == .ourTeam {
                    return "Select Player"
                } else {
                    return "Circle Result"
                }
            case .infraction:
                if requirePlayerForInfractions && selectedTeam == .ourTeam {
                    return "Select Player"
                } else {
                    return "Infraction Details"
                }
            case .turnover:
                if selectedTeam == .ourTeam {
                    return "Select Player"
                } else {
                    return "Confirm Turnover"
                }
            case .goal:
                if selectedTeam == .ourTeam {
                    return "Select Player"
                } else {
                    return "Goal Type"
                }
            }
        case 3:
            switch selectedEventType {
            case .circleEntry: return "Circle Result"
            case .infraction: return "Infraction Details"
            case .goal:
                if selectedTeam == .ourTeam {
                    return "Goal Type"
                } else {
                    return "Goal!"
                }
            case .turnover:
                return "Confirm Turnover"
            }
        case 4:
            return "Goal!"
        default: return "Record Event"
        }
    }
}

// MARK: - Event Type Step
struct EventTypeStep: View {
    @Binding var selectedEventType: EventType
    let onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(EventType.allCases, id: \.self) { type in
                EventTypeCard(
                    type: type,
                    isSelected: selectedEventType == type
                ) {
                    selectedEventType = type
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        onNext()
                    }
                }
            }
        }
    }
}

// MARK: - Event Type Card
struct EventTypeCard: View {
    let type: EventType
    let isSelected: Bool
    let action: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var icon: String {
        switch type {
        case .infraction: return "exclamationmark.triangle.fill"
        case .circleEntry: return "circle.dashed"
        case .turnover: return "arrow.triangle.2.circlepath"
        case .goal: return "soccerball"
        }
    }
    
    private var color: Color {
        switch type {
        case .infraction: return .orange
        case .circleEntry: return .green
        case .turnover: return .red
        case .goal: return .yellow
        }
    }
    
    private var description: String {
        switch type {
        case .infraction: return "Record a foul or violation"
        case .circleEntry: return "Track circle penetration"
        case .turnover: return "Lost possession of the ball"
        case .goal: return "Celebrate a score!"
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(type.rawValue)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                } else {
                    Circle()
                        .stroke(Color(.systemGray4), lineWidth: 2)
                        .frame(width: 24, height: 24)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 8, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Team Selection Step
struct TeamSelectionStep: View {
    @Binding var selectedTeam: TeamType
    let onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            TeamCard(
                title: "Our Team",
                subtitle: "Record event for home team",
                color: .red,
                icon: "house.fill",
                isSelected: selectedTeam == .ourTeam
            ) {
                selectedTeam = .ourTeam
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    onNext()
                }
            }
            
            TeamCard(
                title: "Opponent",
                subtitle: "Record event for away team",
                color: .blue,
                icon: "figure.run",
                isSelected: selectedTeam == .otherTeam
            ) {
                selectedTeam = .otherTeam
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    onNext()
                }
            }
        }
    }
}

// MARK: - Team Card
struct TeamCard: View {
    let title: String
    let subtitle: String
    let color: Color
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(color)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 8, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? color : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Player Selection Step
struct PlayerSelectionStep: View {
    @Binding var selectedPlayerId: UUID?
    let players: [Player]
    let onNext: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("Select a player")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(players.count) players")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            // Player grid
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 70), spacing: 12)], spacing: 12) {
                ForEach(players.sorted(by: { $0.number < $1.number })) { player in
                    PlayerChip(
                        player: player,
                        isSelected: selectedPlayerId == player.id
                    ) {
                        selectedPlayerId = player.id
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            onNext()
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Player Chip
struct PlayerChip: View {
    let player: Player
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.blue : Color(.systemGray5))
                        .frame(width: 50, height: 50)
                    
                    Text("\(player.number)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(isSelected ? .white : .primary)
                }
                
                Text(player.name.split(separator: " ").last.map(String.init) ?? player.name)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(isSelected ? .blue : .secondary)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Player Selection With Skip Step
struct PlayerSelectionWithSkipStep: View {
    @Binding var selectedPlayerId: UUID?
    let players: [Player]
    let onNext: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("Select a player")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(players.count) players")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            // Skip/None option
            Button {
                selectedPlayerId = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    onNext()
                }
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(selectedPlayerId == nil ? Color.gray : Color(.systemGray5))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "forward.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(selectedPlayerId == nil ? .white : .gray)
                    }
                    
                    Text("Skip Player Selection")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(selectedPlayerId == nil ? .primary : .secondary)
                    
                    Spacer()
                    
                    if selectedPlayerId == nil {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.gray)
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(selectedPlayerId == nil ? Color.gray.opacity(0.1) : Color(.systemGray6))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(selectedPlayerId == nil ? Color.gray : Color.clear, lineWidth: 2)
                )
            }
            .buttonStyle(.plain)
            
            // Divider
            HStack {
                Rectangle()
                    .fill(Color(.systemGray4))
                    .frame(height: 1)
                Text("or select player")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                Rectangle()
                    .fill(Color(.systemGray4))
                    .frame(height: 1)
            }
            
            // Player grid
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 70), spacing: 12)], spacing: 12) {
                ForEach(players.sorted(by: { $0.number < $1.number })) { player in
                    PlayerChip(
                        player: player,
                        isSelected: selectedPlayerId == player.id
                    ) {
                        selectedPlayerId = player.id
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            onNext()
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Goal Type Step
struct GoalTypeStep: View {
    @Binding var selectedGoalType: GoalType
    let onNext: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(GoalType.allCases, id: \.self) { type in
                Button {
                    selectedGoalType = type
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        onNext()
                    }
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: type.icon)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(selectedGoalType == type ? .white : .yellow)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(selectedGoalType == type ? Color.yellow : Color.yellow.opacity(0.15))
                            )
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(type.rawValue)
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(.primary)
                            
                            Text(type.description)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if selectedGoalType == type {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.yellow)
                        }
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.05), radius: 4, x: 0, y: 2)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(selectedGoalType == type ? Color.yellow : Color.clear, lineWidth: 2)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Infraction Details Step
struct InfractionDetailsStep: View {
    @Binding var selectedInfraction: InfractionType
    @Binding var selectedCardType: CardType
    let onSave: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 20) {
            // Infraction Type Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Infraction Type")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.secondary)
                
                VStack(spacing: 8) {
                    ForEach(InfractionType.allCases, id: \.self) { infraction in
                        Button {
                            selectedInfraction = infraction
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(infraction.rawValue)
                                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                                        .foregroundColor(.primary)
                                    Text(infraction.description)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                if selectedInfraction == infraction {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.orange)
                                }
                            }
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(selectedInfraction == infraction ? Color.orange.opacity(0.1) : Color(.systemBackground))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(selectedInfraction == infraction ? Color.orange : Color(.systemGray5), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            // Card Type Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Card (Optional)")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.secondary)
                
                HStack(spacing: 10) {
                    ForEach(CardType.allCases, id: \.self) { card in
                        Button {
                            selectedCardType = card
                        } label: {
                            VStack(spacing: 6) {
                                if card == .none {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.gray)
                                        .frame(width: 36, height: 48)
                                        .background(
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(Color(.systemGray5))
                                        )
                                } else {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(card.color)
                                        .frame(width: 36, height: 48)
                                        .shadow(color: card.color.opacity(0.4), radius: 4, x: 0, y: 2)
                                }
                                
                                Text(card == .none ? "None" : card.rawValue.replacingOccurrences(of: " Card", with: ""))
                                    .font(.system(size: 10, weight: .medium, design: .rounded))
                                    .foregroundColor(selectedCardType == card ? .primary : .secondary)
                            }
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(selectedCardType == card ? Color(.systemGray5) : Color.clear)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(selectedCardType == card ? Color.blue : Color.clear, lineWidth: 2)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            // Save Button
            Button {
                onSave()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                    Text("Save Infraction")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.orange)
                )
            }
            .padding(.top, 8)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6).opacity(0.5))
        )
    }
}

// MARK: - Circle Result Step
struct CircleResultStep: View {
    @Binding var selectedCircleResult: CircleResult
    let onSave: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    private func iconFor(_ result: CircleResult) -> String {
        switch result {
        case .goal: return "soccerball"
        case .penaltyCorner: return "flag.fill"
        case .shotSaved: return "hand.raised.fill"
        case .shotWide: return "arrow.right.to.line"
        case .turnover: return "arrow.triangle.2.circlepath"
        case .longCorner: return "flag.fill"
        case .nothing: return "minus.circle"
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(CircleResult.allCases, id: \.self) { result in
                Button {
                    selectedCircleResult = result
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        onSave()
                    }
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: iconFor(result))
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(selectedCircleResult == result ? .white : .green)
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(selectedCircleResult == result ? Color.green : Color.green.opacity(0.1))
                            )
                        
                        Text(result.rawValue)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if selectedCircleResult == result {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.green)
                        }
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.05), radius: 4, x: 0, y: 2)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(selectedCircleResult == result ? Color.green : Color.clear, lineWidth: 2)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Goal Confirm Step
struct GoalConfirmStep: View {
    let selectedGoalType: GoalType
    let onSave: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var animateScale = false
    
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.yellow.opacity(0.3), Color.yellow.opacity(0.05)],
                            center: .center,
                            startRadius: 20,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                
                Image(systemName: "soccerball")
                    .font(.system(size: 70))
                    .foregroundColor(.yellow)
                    .scaleEffect(animateScale ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: animateScale)
            }
            
            VStack(spacing: 8) {
                Text("GOAL!")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(colors: [.yellow, .orange], startPoint: .leading, endPoint: .trailing)
                    )
                
                // Goal type badge
                HStack(spacing: 6) {
                    Image(systemName: selectedGoalType.icon)
                        .font(.system(size: 12, weight: .semibold))
                    Text(selectedGoalType.rawValue)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.yellow)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.yellow.opacity(0.15))
                )
                
                Text("This will update the score automatically")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
            
            Button {
                onSave()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                    Text("Save Goal")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.yellow)
                )
            }
            .padding(.top, 8)
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 12, x: 0, y: 6)
        )
        .onAppear {
            animateScale = true
        }
    }
}

// MARK: - Turnover Confirm Step
struct TurnoverConfirmStep: View {
    let onSave: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var animateRotation = false
    
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.red.opacity(0.3), Color.red.opacity(0.05)],
                            center: .center,
                            startRadius: 20,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 60))
                    .foregroundColor(.red)
                    .rotationEffect(.degrees(animateRotation ? 360 : 0))
                    .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: animateRotation)
            }
            
            VStack(spacing: 8) {
                Text("Turnover")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(colors: [.red, .orange], startPoint: .leading, endPoint: .trailing)
                    )
                
                Text("Lost possession recorded")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
            
            Button {
                onSave()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                    Text("Save Turnover")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.red)
                )
            }
            .padding(.top, 8)
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 12, x: 0, y: 6)
        )
        .onAppear {
            animateRotation = true
        }
    }
}
