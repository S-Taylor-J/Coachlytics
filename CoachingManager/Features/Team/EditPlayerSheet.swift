//
//  EditPlayerSheet.swift
//  CoachingManager
//
//  Created by Taylor Santos on 06/01/2026.
//

import Foundation
import SwiftUI
import SwiftData

struct EditPlayerSheet: View, Identifiable {
    let id = UUID()
    let player: Player
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Team.name) private var teams: [Team]
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var customOptionsManager = CustomOptionsManager.shared
    
    @State private var playerName: String
    @State private var playerNumber: String
    @State private var selectedPositions: Set<String>
    @State private var selectedSkills: Set<String>
    
    private var positions: [String] {
        customOptionsManager.allPositions
    }
    
    private var skills: [String] {
        customOptionsManager.allSkills
    }
    
    init(player: Player) {
        self.player = player
        _playerName = State(initialValue: player.name)
        _playerNumber = State(initialValue: String(player.number))
        _selectedPositions = State(initialValue: Set(player.positions))
        _selectedSkills = State(initialValue: Set(player.skills))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        editHero
                        playerFieldsCard
                        positionsCard
                        skillsCard
                        teamMembershipCard
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 36)
                }
            }
            .navigationTitle("Edit Player")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(playerName.isEmpty || playerNumber.isEmpty)
                }
            }
        }
    }

    private var editHero: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.accentColor, Color(red: 0.17, green: 0.35, blue: 1.0)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                    .shadow(color: Color.accentColor.opacity(0.28), radius: 16, x: 0, y: 10)

                Text("#\(player.number)")
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text("Player Profile")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .tracking(1.1)
                    .foregroundStyle(Color.accentColor)
                Text(player.name)
                    .font(.system(size: 27, weight: .black, design: .rounded))
                    .foregroundStyle(primaryText)
                    .lineLimit(1)
                Text("Update roster details, roles, and team assignments")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(textMuted)
            }

            Spacer()
        }
        .padding(18)
        .background(cardSurface(accent: .accentColor))
    }

    private var playerFieldsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Player Info", icon: "person.text.rectangle.fill", tint: .accentColor)

            VStack(spacing: 12) {
                editField(icon: "person.fill", placeholder: "Player Name", text: $playerName)
                editField(icon: "number", placeholder: "Jersey Number", text: $playerNumber)
                    .keyboardType(.numberPad)
            }
        }
        .padding(16)
        .background(cardSurface(accent: .accentColor))
    }

    private var positionsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                sectionHeader("Positions", icon: "sportscourt.fill", tint: .blue)
                Spacer()
                if !selectedPositions.isEmpty {
                    Text("\(selectedPositions.count) selected")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.blue)
                }
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(positions, id: \.self) { position in
                    PositionChip(
                        title: position,
                        icon: iconForPosition(position),
                        isSelected: selectedPositions.contains(position),
                        isCustom: customOptionsManager.isCustomPosition(position)
                    ) {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
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
        .padding(16)
        .background(cardSurface(accent: .blue))
    }

    private var skillsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                sectionHeader("Skills", icon: "star.fill", tint: .orange)
                Spacer()
                if !selectedSkills.isEmpty {
                    Text("\(selectedSkills.count) selected")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.orange)
                }
            }

            FlowLayout(spacing: 10) {
                ForEach(skills, id: \.self) { skill in
                    SkillTag(
                        title: skill,
                        isSelected: selectedSkills.contains(skill),
                        isCustom: customOptionsManager.isCustomSkill(skill)
                    ) {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
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
        .padding(16)
        .background(cardSurface(accent: .orange))
    }

    private var teamMembershipCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Teams", icon: "person.3.fill", tint: .purple)

            if teams.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.orange)
                    Text("No teams created yet")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(textMuted)
                    Spacer()
                }
                .padding(14)
                .background(fieldSurface)
            } else {
                VStack(spacing: 10) {
                    ForEach(teams) { team in
                        teamMembershipRow(team)
                    }
                }
            }
        }
        .padding(16)
        .background(cardSurface(accent: .purple))
    }

    private func teamMembershipRow(_ team: Team) -> some View {
        let isSelected = player.teams.contains(where: { $0.id == team.id })

        return Button {
            toggleTeamMembership(team: team)
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.purple.opacity(0.16) : Color.secondary.opacity(0.10))
                        .frame(width: 44, height: 44)

                    Image(systemName: "person.3.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(isSelected ? .purple : .secondary)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(team.name)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(primaryText)
                    Text("\(team.players.count) player\(team.players.count == 1 ? "" : "s")")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(textMuted)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(isSelected ? .green : Color.secondary.opacity(0.6))
            }
            .padding(14)
            .background(fieldSurface)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? Color.green.opacity(0.45) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func sectionHeader(_ title: String, icon: String, tint: Color) -> some View {
        Label {
            Text(title)
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundStyle(primaryText)
        } icon: {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(tint)
        }
    }

    private func editField(icon: String, placeholder: String, text: Binding<String>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.accentColor)
                .frame(width: 20)

            TextField(placeholder, text: text)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(primaryText)
        }
        .padding(15)
        .background(fieldSurface)
    }

    private var backgroundColor: Color {
        colorScheme == .dark ? Color(red: 0.05, green: 0.06, blue: 0.09) : Color(red: 0.97, green: 0.98, blue: 1.0)
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: colorScheme == .dark ? [
                Color(red: 0.015, green: 0.026, blue: 0.045),
                Color(red: 0.034, green: 0.052, blue: 0.086),
                Color(red: 0.015, green: 0.018, blue: 0.030)
            ] : [
                Color(red: 0.965, green: 0.980, blue: 1.000),
                Color(red: 0.925, green: 0.950, blue: 0.990),
                Color(red: 0.985, green: 0.990, blue: 1.000)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
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

    private var strokeColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.10) : Color(red: 0.55, green: 0.64, blue: 0.78).opacity(0.24)
    }

    private var fieldSurface: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(.ultraThinMaterial)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.060) : Color.white.opacity(0.78))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
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

    private func iconForPosition(_ position: String) -> String {
        switch position {
        case "Goalkeeper": return "hand.raised.fill"
        case "Defender": return "shield.fill"
        case "Midfielder": return "arrow.left.arrow.right"
        case "Forward": return "scope"
        default: return "person.fill"
        }
    }

    private func toggleTeamMembership(team: Team) {
        if player.teams.contains(where: { $0.id == team.id }) {
            // Remove from team
            if let playerIndex = player.teams.firstIndex(where: { $0.id == team.id }) {
                player.teams.remove(at: playerIndex)
            }
            if let teamIndex = team.players.firstIndex(where: { $0.id == player.id }) {
                team.players.remove(at: teamIndex)
            }
        } else {
            // Add to team
            player.teams.append(team)
            team.players.append(player)
        }
        
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    private func saveChanges() {
        // Update the player object directly
        player.name = playerName
        player.number = Int(playerNumber) ?? player.number
        player.positions = Array(selectedPositions)
        player.skills = Array(selectedSkills)
        
        dismiss()
    }
}
