//
//  TeamAssignmentSheet.swift
//  CoachingManager
//
//  Created by Taylor Santos on 06/01/2026.
//

import Foundation
import SwiftUI
import SwiftData

struct TeamAssignmentSheet: View, Identifiable {
    let id = UUID()
    let player: Player
    @Binding var selectedTeam: Team?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \Team.name) private var teams: [Team]
    
    var body: some View {
        NavigationStack {
            List {
                Section("Add to Teams") {
                    ForEach(teams) { team in
                        Button {
                            toggleTeamMembership(team: team)
                        } label: {
                            HStack {
                                Text(team.name)
                                Spacer()
                                
                                if player.teams.contains(where: { $0.id == team.id }) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                }
            }
            .navigationTitle("Add \(player.name) to Teams")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
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
    }
}
