//
//  AddPlayerSheet.swift
//  CoachingManager
//
//  Created by Taylor Santos on 06/01/2026.
//

import Foundation
import SwiftUI
import SwiftData

struct AddPlayerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.colorScheme) private var colorScheme
    @Query(sort: \Team.name) private var teams: [Team]
    @StateObject private var customOptionsManager = CustomOptionsManager.shared
    @State private var playerName = ""
    @State private var playerNumber = ""
    @State private var selectedPositions: Set<String> = []
    @State private var selectedSkills: Set<String> = []
    @State private var selectedTeamForPlayer: Team?
    @FocusState private var focusedField: Field?
    
    enum Field {
        case name, number
    }
    
    private var positions: [String] {
        customOptionsManager.allPositions
    }
    
    private var skills: [String] {
        customOptionsManager.allSkills
    }
    
    var selectedTeam: Team?
    
    private var canSave: Bool {
        !playerName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !playerNumber.isEmpty &&
        Int(playerNumber) != nil
    }
    
    private func iconForPosition(_ position: String) -> String {
        switch position {
        case "Goalkeeper": return "hand.raised.fill"
        case "Defender": return "shield.fill"
        case "Midfielder": return "arrow.left.arrow.right"
        case "Forward": return "scope"
        default: return "person.fill" // Default icon for custom positions
        }
    }
    
    private var positionIcons: [String: String] {
        [
            "Goalkeeper": "hand.raised.fill",
            "Defender": "shield.fill",
            "Midfielder": "arrow.left.arrow.right",
            "Forward": "scope"
        ]
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()

                ScrollView {
                    VStack(spacing: 24) {
                        sheetHero
                        playerInfoSection

                        teamSection

                        positionSection

                        skillsSection
                    }
                    .padding()
                }
            }
            .navigationTitle("New Player")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        savePlayer()
                    } label: {
                        Text("Save")
                            .fontWeight(.semibold)
                    }
                    .disabled(!canSave)
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        focusedField = nil
                    }
                }
            }
        }
    }
    
    // MARK: - Player Info Section
    private var sheetHero: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.brandAccent, AppTheme.brandDeepBlue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                    .shadow(color: AppTheme.brandAccent.opacity(0.28), radius: 16, x: 0, y: 10)

                Image(systemName: "person.crop.circle.badge.plus")
                    .font(.system(size: 25, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text("Roster Builder")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .tracking(1.1)
                    .foregroundStyle(AppTheme.brandAccent)
                Text("Add Player")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(primaryText)
                Text("Create a profile with team, positions, and skills")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(textMuted)
            }

            Spacer()
        }
        .padding(18)
        .background(cardSurface(accent: AppTheme.brandAccent))
    }

    private var playerInfoSection: some View {
        VStack(spacing: 16) {
            // Section Header
            HStack {
                Label("Player Info", systemImage: "person.fill")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
                if !canSave {
                    Text("Required")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            VStack(spacing: 12) {
                // Name Field
                VStack(alignment: .leading, spacing: 6) {
                    Text("Name")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    HStack {
                        Image(systemName: "person.text.rectangle")
                            .foregroundStyle(AppTheme.brandAccent)
                            .frame(width: 24)
                        
                        TextField("Enter player's name", text: $playerName)
                            .textContentType(.name)
                            .autocorrectionDisabled()
                            .focused($focusedField, equals: .name)
                            .submitLabel(.next)
                            .onSubmit {
                                focusedField = .number
                            }
                    }
                    .padding()
                    .background(fieldSurface)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(focusedField == .name ? AppTheme.brandAccent : Color.clear, lineWidth: 2)
                    )
                }
                
                // Number Field
                VStack(alignment: .leading, spacing: 6) {
                    Text("Jersey Number")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    HStack {
                        Image(systemName: "number")
                            .foregroundStyle(AppTheme.brandAccent)
                            .frame(width: 24)
                        
                        TextField("Enter jersey number", text: $playerNumber)
                            .keyboardType(.numberPad)
                            .focused($focusedField, equals: .number)
                    }
                    .padding()
                    .background(fieldSurface)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(focusedField == .number ? AppTheme.brandAccent : Color.clear, lineWidth: 2)
                    )
                }
            }
        }
        .padding()
        .background(cardSurface(accent: AppTheme.brandAccent))
    }
    
    // MARK: - Team Section
    private var teamSection: some View {
        VStack(spacing: 16) {
            HStack {
                Label("Team", systemImage: "person.3.fill")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
            }
            
            if let preSelectedTeam = selectedTeam {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.brandAccent.opacity(0.15))
                            .frame(width: 44, height: 44)
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(AppTheme.brandAccent)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(preSelectedTeam.name)
                            .font(.body.weight(.medium))
                        Text("Player will be added to this team")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(fieldSurface)
                .cornerRadius(12)
            } else if teams.isEmpty {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.warning.opacity(0.15))
                            .frame(width: 44, height: 44)
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.title2)
                            .foregroundStyle(AppTheme.warning)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("No Teams Available")
                            .font(.body.weight(.medium))
                        Text("Create a team first to assign this player")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(fieldSurface)
                .cornerRadius(12)
            } else {
                VStack(spacing: 8) {
                    ForEach(teams) { team in
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                if selectedTeamForPlayer?.id == team.id {
                                    selectedTeamForPlayer = nil
                                } else {
                                    selectedTeamForPlayer = team
                                }
                            }
                        } label: {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(selectedTeamForPlayer?.id == team.id ? AppTheme.brandAccent.opacity(0.15) : Color.gray.opacity(0.1))
                                        .frame(width: 44, height: 44)
                                    Image(systemName: selectedTeamForPlayer?.id == team.id ? "checkmark.circle.fill" : "circle")
                                        .font(.title2)
                                        .foregroundStyle(selectedTeamForPlayer?.id == team.id ? AppTheme.brandAccent : .gray.opacity(0.5))
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(team.name)
                                        .font(.body.weight(.medium))
                                        .foregroundStyle(.primary)
                                    Text("\(team.players.count) player\(team.players.count == 1 ? "" : "s")")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                            }
                            .padding()
                            .background(fieldSurface)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(selectedTeamForPlayer?.id == team.id ? AppTheme.brandAccent : Color.clear, lineWidth: 2)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // No team option
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            selectedTeamForPlayer = nil
                        }
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(selectedTeamForPlayer == nil ? Color.gray.opacity(0.15) : Color.gray.opacity(0.1))
                                    .frame(width: 44, height: 44)
                                Image(systemName: selectedTeamForPlayer == nil ? "circle.dashed" : "circle")
                                    .font(.title2)
                                    .foregroundStyle(selectedTeamForPlayer == nil ? .gray : .gray.opacity(0.5))
                            }
                            
                            Text("No Team")
                                .font(.body.weight(.medium))
                                .foregroundStyle(.secondary)
                            
                            Spacer()
                        }
                        .padding()
                        .background(fieldSurface)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(selectedTeamForPlayer == nil ? Color.gray.opacity(0.5) : Color.clear, lineWidth: 2)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .background(cardSurface(accent: AppTheme.brandAccent))
    }
    
    // MARK: - Position Section
    private var positionSection: some View {
        VStack(spacing: 16) {
            HStack {
                Label("Position", systemImage: "sportscourt.fill")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
                if !selectedPositions.isEmpty {
                    Text("\(selectedPositions.count) selected")
                        .font(.caption)
                        .foregroundStyle(AppTheme.brandAccent)
                }
            }
            
            Text("Select all positions this player can play")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(positions, id: \.self) { position in
                    PositionChip(
                        title: position,
                        icon: iconForPosition(position),
                        isSelected: selectedPositions.contains(position),
                        isCustom: customOptionsManager.isCustomPosition(position)
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            if selectedPositions.contains(position) {
                                selectedPositions.remove(position)
                            } else {
                                selectedPositions.insert(position)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(cardSurface(accent: AppTheme.brandAccent))
    }
    
    // MARK: - Skills Section
    private var skillsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Label("Special Skills", systemImage: "star.fill")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
                if !selectedSkills.isEmpty {
                    Text("\(selectedSkills.count) selected")
                        .font(.caption)
                        .foregroundStyle(AppTheme.brandAccent)
                }
            }
            
            Text("Select any special skills or roles")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            FlowLayout(spacing: 10) {
                ForEach(skills, id: \.self) { skill in
                    SkillTag(
                        title: skill,
                        isSelected: selectedSkills.contains(skill),
                        isCustom: customOptionsManager.isCustomSkill(skill)
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            if selectedSkills.contains(skill) {
                                selectedSkills.remove(skill)
                            } else {
                                selectedSkills.insert(skill)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(cardSurface(accent: AppTheme.brandAccent))
    }

    private var primaryText: Color {
        colorScheme == .dark ? .white : Color(red: 0.035, green: 0.055, blue: 0.090)
    }

    private var textMuted: Color {
        colorScheme == .dark ? Color.white.opacity(0.54) : Color(red: 0.45, green: 0.50, blue: 0.60)
    }

    private var surfaceFill: Color {
        colorScheme == .dark ? Color.white.opacity(0.065) : Color.white.opacity(0.86)
    }

    private var fieldFill: Color {
        colorScheme == .dark ? Color.white.opacity(0.060) : Color.white.opacity(0.78)
    }

    private var strokeColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.10) : Color(red: 0.55, green: 0.64, blue: 0.78).opacity(0.24)
    }

    private var fieldSurface: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(.ultraThinMaterial)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(fieldFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(strokeColor, lineWidth: 1)
            )
    }

    private func cardSurface(accent: Color) -> some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(.ultraThinMaterial)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(surfaceFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(accent.opacity(0.22), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.22 : 0.10), radius: 14, x: 0, y: 8)
    }
    
    private func savePlayer() {
        guard let number = Int(playerNumber) else { return }
        
        let player = Player(
            name: playerName.trimmingCharacters(in: .whitespaces),
            number: number,
            positions: Array(selectedPositions),
            skills: Array(selectedSkills)
        )
        
        context.insert(player)
        
        // Add to pre-selected team if any, otherwise use the picker selection
        let teamToAdd = selectedTeam ?? selectedTeamForPlayer
        if let team = teamToAdd {
            player.teams.append(team)
            team.players.append(player)
        }
        
        dismiss()
    }
}

// MARK: - Position Chip Component
struct PositionChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    var isCustom: Bool = false
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: icon)
                        .font(.body)
                    if isCustom {
                        Circle()
                            .fill(AppTheme.warning)
                            .frame(width: 6, height: 6)
                            .offset(x: 2, y: -2)
                    }
                }
                Text(title)
                    .font(.subheadline.weight(.medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 12)
            .background(isSelected ? AppTheme.brandAccent.opacity(0.15) : surfaceFill)
            .foregroundStyle(isSelected ? AppTheme.brandAccent : primaryText)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? AppTheme.brandAccent : strokeColor, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var primaryText: Color { colorScheme == .dark ? .white : Color(red: 0.04, green: 0.06, blue: 0.10) }
    private var surfaceFill: Color { colorScheme == .dark ? Color.white.opacity(0.060) : Color.white.opacity(0.78) }
    private var strokeColor: Color { colorScheme == .dark ? Color.white.opacity(0.10) : Color(red: 0.55, green: 0.64, blue: 0.78).opacity(0.24) }
}

// MARK: - Skill Tag Component
struct SkillTag: View {
    let title: String
    let isSelected: Bool
    var isCustom: Bool = false
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                if isCustom {
                    Image(systemName: "star.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(isSelected ? .white.opacity(0.8) : AppTheme.warning)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isSelected ? AppTheme.brandAccent : surfaceFill)
            .foregroundStyle(isSelected ? .white : primaryText)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? AppTheme.brandAccent : strokeColor, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var primaryText: Color { colorScheme == .dark ? .white : Color(red: 0.04, green: 0.06, blue: 0.10) }
    private var surfaceFill: Color { colorScheme == .dark ? Color.white.opacity(0.060) : Color.white.opacity(0.78) }
    private var strokeColor: Color { colorScheme == .dark ? Color.white.opacity(0.10) : Color(red: 0.55, green: 0.64, blue: 0.78).opacity(0.24) }
}

// MARK: - Flow Layout for Skills
struct FlowLayout: Layout {
    var spacing: CGFloat = 10
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                          proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var positions: [CGPoint] = []
        var size: CGSize = .zero
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
                self.size.width = max(self.size.width, x)
            }
            
            self.size.height = y + rowHeight
        }
    }
}
