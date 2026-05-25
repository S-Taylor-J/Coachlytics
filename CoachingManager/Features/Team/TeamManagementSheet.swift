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
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color(red: 0.05, green: 0.06, blue: 0.09) : Color(red: 0.97, green: 0.98, blue: 1.0)
    }

    private var backgroundGradient: some View {
        ZStack {
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

            LinearGradient(
                colors: [
                    Color.accentColor.opacity(colorScheme == .dark ? 0.14 : 0.16),
                    Color.clear,
                    Color.green.opacity(colorScheme == .dark ? 0.05 : 0.10)
                ],
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
        }
    }

    private var primaryText: Color {
        colorScheme == .dark ? .white : Color(red: 0.035, green: 0.055, blue: 0.090)
    }

    private var surfaceFill: Color {
        colorScheme == .dark ? Color.white.opacity(0.065) : Color.white.opacity(0.86)
    }

    private var strokeColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.10) : Color(red: 0.55, green: 0.64, blue: 0.78).opacity(0.24)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        headerCard
                            .padding(.top, 8)

                        if !teams.isEmpty {
                            teamsSection
                        } else {
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
            }
            .navigationTitle("Manage Teams")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
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
                        .fill(Color.accentColor)
                        .frame(width: 56, height: 56)
                        .shadow(color: Color.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                    
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Teams")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundStyle(primaryText)
                    
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
                .foregroundColor(.accentColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.accentColor.opacity(0.12))
                )
            }
        }
        .padding(16)
        .background(cardSurface(accent: .accentColor))
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
                    .fill(.ultraThinMaterial)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(surfaceFill)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(strokeColor, lineWidth: 1)
                    )
            )
        }
    }
    
    private func teamRow(team: Team) -> some View {
        HStack(spacing: 14) {
            // Team Badge
            ZStack {
                Circle()
                    .fill(selectedTeam?.id == team.id ? Color.accentColor : Color(.systemGray4))
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
                        .foregroundColor(.accentColor)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Color.accentColor.opacity(0.12)))
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
                    .foregroundColor(.accentColor)
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
