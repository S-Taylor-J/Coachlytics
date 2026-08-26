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
            .background(AppBackgroundView())
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
    
    // MARK: - Progress Bar
    private var progressBar: some View {
        HStack(spacing: 4) {
            ForEach(0..<getTotalSteps(), id: \.self) { step in
                Capsule()
                    .fill(step <= currentStep ? AppTheme.brandAccent : AppTheme.strokeColor(colorScheme))
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
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(AppTheme.surfaceFill(colorScheme))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(AppTheme.strokeColor(colorScheme), lineWidth: 1)
                    )
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
        case .infraction: return AppTheme.warning
        case .circleEntry: return AppTheme.success
        case .turnover: return AppTheme.danger
        case .goal: return AppTheme.goldAccent
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
                        .foregroundColor(AppTheme.brandAccent)
                } else {
                    Circle()
                        .stroke(AppTheme.strokeColor(colorScheme), lineWidth: 2)
                        .frame(width: 24, height: 24)
                }
            }
            .padding(16)
            .background(
                GameCardSurface(accent: isSelected ? color : .gray)
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
                GameCardSurface(accent: isSelected ? color : .gray)
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
            GameCardSurface(accent: AppTheme.brandAccent)
        )
    }
}

// MARK: - Player Chip
struct PlayerChip: View {
    let player: Player
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(isSelected ? AppTheme.brandAccent : AppTheme.secondarySurfaceFill(colorScheme))
                        .frame(width: 50, height: 50)
                    
                    Text("\(player.number)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(isSelected ? .white : .primary)
                }
                
                Text(player.name.split(separator: " ").last.map(String.init) ?? player.name)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(isSelected ? AppTheme.brandAccent : .secondary)
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
                            .fill(selectedPlayerId == nil ? Color.gray : AppTheme.secondarySurfaceFill(colorScheme))
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
                        .fill(selectedPlayerId == nil ? Color.gray.opacity(0.1) : AppTheme.secondarySurfaceFill(colorScheme))
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
                    .fill(AppTheme.strokeColor(colorScheme))
                    .frame(height: 1)
                Text("or select player")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                Rectangle()
                    .fill(AppTheme.strokeColor(colorScheme))
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
            GameCardSurface(accent: AppTheme.brandAccent)
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
                            .foregroundColor(selectedGoalType == type ? .white : AppTheme.goldAccent)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(selectedGoalType == type ? AppTheme.goldAccent : AppTheme.goldAccent.opacity(0.15))
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
                                .foregroundColor(AppTheme.goldAccent)
                        }
                    }
                    .padding(14)
                    .background(
                        GameCardSurface(accent: selectedGoalType == type ? AppTheme.goldAccent : .gray, cornerRadius: 14)
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
                                        .foregroundColor(AppTheme.warning)
                                }
                            }
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(selectedInfraction == infraction ? AppTheme.warning.opacity(0.1) : AppTheme.surfaceFill(colorScheme))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(selectedInfraction == infraction ? AppTheme.warning : AppTheme.strokeColor(colorScheme), lineWidth: 1)
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
                                                .fill(AppTheme.secondarySurfaceFill(colorScheme))
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
                                    .fill(selectedCardType == card ? AppTheme.secondarySurfaceFill(colorScheme) : Color.clear)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(selectedCardType == card ? AppTheme.brandAccent : Color.clear, lineWidth: 2)
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
                        .fill(AppTheme.warning)
                )
            }
            .padding(.top, 8)
        }
        .padding(16)
        .background(
            GameCardSurface(accent: AppTheme.warning)
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
                            .foregroundColor(selectedCircleResult == result ? .white : AppTheme.success)
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(selectedCircleResult == result ? AppTheme.success : AppTheme.success.opacity(0.1))
                            )
                        
                        Text(result.rawValue)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if selectedCircleResult == result {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(AppTheme.success)
                        }
                    }
                    .padding(14)
                    .background(
                        GameCardSurface(accent: selectedCircleResult == result ? AppTheme.success : .gray, cornerRadius: 14)
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
                            colors: [AppTheme.goldAccent.opacity(0.3), AppTheme.goldAccent.opacity(0.05)],
                            center: .center,
                            startRadius: 20,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                
                Image(systemName: "soccerball")
                    .font(.system(size: 70))
                    .foregroundColor(AppTheme.goldAccent)
                    .scaleEffect(animateScale ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: animateScale)
            }
            
            VStack(spacing: 8) {
                Text("GOAL!")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(colors: [AppTheme.goldAccent, AppTheme.warning], startPoint: .leading, endPoint: .trailing)
                    )
                
                // Goal type badge
                HStack(spacing: 6) {
                    Image(systemName: selectedGoalType.icon)
                        .font(.system(size: 12, weight: .semibold))
                    Text(selectedGoalType.rawValue)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                }
                .foregroundColor(AppTheme.goldAccent)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(AppTheme.goldAccent.opacity(0.15))
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
                        .fill(AppTheme.goldAccent)
                )
            }
            .padding(.top, 8)
        }
        .padding(32)
        .background(
            GameCardSurface(accent: AppTheme.goldAccent, cornerRadius: 20)
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
                            colors: [AppTheme.danger.opacity(0.3), AppTheme.danger.opacity(0.05)],
                            center: .center,
                            startRadius: 20,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 60))
                    .foregroundColor(AppTheme.danger)
                    .rotationEffect(.degrees(animateRotation ? 360 : 0))
                    .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: animateRotation)
            }
            
            VStack(spacing: 8) {
                Text("Turnover")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(colors: [AppTheme.danger, AppTheme.warning], startPoint: .leading, endPoint: .trailing)
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
                        .fill(AppTheme.danger)
                )
            }
            .padding(.top, 8)
        }
        .padding(32)
        .background(
            GameCardSurface(accent: AppTheme.danger, cornerRadius: 20)
        )
        .onAppear {
            animateRotation = true
        }
    }
}

private struct GameCardSurface: View {
    let accent: Color
    var cornerRadius: CGFloat = 16

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(.ultraThinMaterial)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.04) : Color.white.opacity(0.6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(accent.opacity(colorScheme == .dark ? 0.4 : 0.25), lineWidth: 1)
            )
            .shadow(color: accent.opacity(colorScheme == .dark ? 0.16 : 0.12), radius: 12, x: 0, y: 8)
    }
}
