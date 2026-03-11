//
//  TeamManagementSheet.swift
//  CoachingManager
//
//  Created by Taylor Santos on 06/01/2026.
//

import Foundation
import SwiftUI
import SwiftData

struct TeamManagementSheet: View {
    let teams: [Team]
    @Binding var selectedTeam: Team?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingDeleteAlert = false
    @State private var teamToDelete: Team?
    @State private var showCreateTeamSheet = false
    @State private var teamToEdit: Team?
    @State private var editedTeamName = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Header Card
                    headerCard
                        .padding(.top, 8)
                    
                    // Teams Section
                    if !teams.isEmpty {
                        teamsSection
                    } else {
                        // Empty state
                        VStack(spacing: 12) {
                            Image(systemName: "person.3")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary.opacity(0.5))
                            Text("No teams yet")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.secondary)
                            Text("Tap 'New Team' above to create one")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary.opacity(0.7))
                        }
                        .padding(.vertical, 40)
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Manage Teams")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.medium)
                }
            }
            .sheet(isPresented: $showCreateTeamSheet) {
                CreateTeamSheet { newTeam in
                    selectedTeam = newTeam
                }
            }
            .alert("Delete Team", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let team = teamToDelete {
                        deleteTeam(team)
                    }
                }
            } message: {
                if let team = teamToDelete {
                    Text("Are you sure you want to delete \"\(team.name)\" and remove all player associations?")
                }
            }
            .alert("Rename Team", isPresented: .init(
                get: { teamToEdit != nil },
                set: { if !$0 { teamToEdit = nil; editedTeamName = "" } }
            )) {
                TextField("Team Name", text: $editedTeamName)
                Button("Cancel", role: .cancel) {
                    teamToEdit = nil
                    editedTeamName = ""
                }
                Button("Save") {
                    if let team = teamToEdit {
                        team.name = editedTeamName.trimmingCharacters(in: .whitespaces)
                        teamToEdit = nil
                        editedTeamName = ""
                    }
                }
                .disabled(editedTeamName.trimmingCharacters(in: .whitespaces).isEmpty)
            } message: {
                Text("Enter a new name for the team")
            }
        }
    }
    
    // MARK: - Header Card
    private var headerCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.purple, .purple.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                        .shadow(color: .purple.opacity(0.3), radius: 8, x: 0, y: 4)
                    
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Teams")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                    
                    Text("\(teams.count) team\(teams.count == 1 ? "" : "s") • \(teams.reduce(0) { $0 + $1.players.count }) players total")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Quick action - Create new team inline
            Button {
                showCreateTeamSheet = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                    Text("New Team")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.green)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.green.opacity(0.12))
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 8, x: 0, y: 4)
        )
    }
    
    // MARK: - Teams Section
    private var teamsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Select a Team")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Tap to select")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary.opacity(0.6))
            }
            .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                ForEach(Array(teams.enumerated()), id: \.element.id) { index, team in
                    teamRow(team: team)
                    
                    if index < teams.count - 1 {
                        Divider()
                            .padding(.leading, 72)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
            )
        }
    }
    
    private func teamRow(team: Team) -> some View {
        HStack(spacing: 14) {
            // Team Badge
            ZStack {
                Circle()
                    .fill(
                        selectedTeam?.id == team.id
                            ? LinearGradient(colors: [.purple, .purple.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(colors: [Color(.systemGray4), Color(.systemGray4).opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 44, height: 44)
                
                Image(systemName: "person.3.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(team.name)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("\(team.players.count) player\(team.players.count == 1 ? "" : "s")")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Quick actions
            HStack(spacing: 8) {
                // Rename button
                Button {
                    teamToEdit = team
                    editedTeamName = team.name
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.blue)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Color.blue.opacity(0.12)))
                }
                .buttonStyle(.plain)
                
                // Delete button
                Button {
                    teamToDelete = team
                    showingDeleteAlert = true
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.red)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Color.red.opacity(0.12)))
                }
                .buttonStyle(.plain)
            }
            
            if selectedTeam?.id == team.id {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.purple)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(14)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTeam = team
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            dismiss()
        }
    }
    
    private func deleteTeam(_ team: Team) {
        // Remove team from all players
        for player in team.players {
            if let index = player.teams.firstIndex(where: { $0.id == team.id }) {
                player.teams.remove(at: index)
            }
        }
        
        context.delete(team)
        
        if selectedTeam?.id == team.id {
            selectedTeam = nil
        }
        
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
