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
            Form {
                Section("Player Info") {
                    TextField("Player Name", text: $playerName)
                    TextField("Jersey Number", text: $playerNumber)
                        .keyboardType(.numberPad)
                }                
                Section("Position") {
                    ForEach(positions, id: \.self) { position in
                        Button {
                            if selectedPositions.contains(position) {
                                selectedPositions.remove(position)
                            } else {
                                selectedPositions.insert(position)
                            }
                        } label: {
                            HStack {
                                Text(position)
                                if customOptionsManager.isCustomPosition(position) {
                                    Image(systemName: "star.circle.fill")
                                        .font(.caption)
                                        .foregroundStyle(.orange)
                                }
                                Spacer()
                                if selectedPositions.contains(position) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                }
                
                Section("Skills") {
                    ForEach(skills, id: \.self) { skill in
                        Button {
                            if selectedSkills.contains(skill) {
                                selectedSkills.remove(skill)
                            } else {
                                selectedSkills.insert(skill)
                            }
                        } label: {
                            HStack {
                                Text(skill)
                                if customOptionsManager.isCustomSkill(skill) {
                                    Image(systemName: "star.circle.fill")
                                        .font(.caption)
                                        .foregroundStyle(.orange)
                                }
                                Spacer()
                                if selectedSkills.contains(skill) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                }
                // MARK: - Teams Section
                Section {
                    if teams.isEmpty {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("No teams created yet")
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        ForEach(teams) { team in
                            Button {
                                toggleTeamMembership(team: team)
                            } label: {
                                HStack {
                                    ZStack {
                                        Circle()
                                            .fill(player.teams.contains(where: { $0.id == team.id })
                                                ? Color.purple.opacity(0.15)
                                                : Color(.systemGray5))
                                            .frame(width: 36, height: 36)
                                        
                                        Image(systemName: "person.3.fill")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(player.teams.contains(where: { $0.id == team.id })
                                                ? .purple
                                                : .secondary)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(team.name)
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(.primary)
                                        Text("\(team.players.count) players")
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    if player.teams.contains(where: { $0.id == team.id }) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 22))
                                            .foregroundStyle(.green)
                                    } else {
                                        Image(systemName: "circle")
                                            .font(.system(size: 22))
                                            .foregroundStyle(Color(.systemGray3))
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } header: {
                    Text("Teams")
                }
            }
            .navigationTitle("Edit Player")
            .navigationBarTitleDisplayMode(.inline)
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
