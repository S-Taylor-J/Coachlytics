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
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        assignmentHero

                        VStack(alignment: .leading, spacing: 14) {
                            Label("Add to Teams", systemImage: "person.3.fill")
                                .font(.system(size: 15, weight: .black, design: .rounded))
                                .foregroundStyle(primaryText)

                            if teams.isEmpty {
                                emptyTeamsState
                            } else {
                                VStack(spacing: 10) {
                                    ForEach(teams) { team in
                                        assignmentRow(team)
                                    }
                                }
                            }
                        }
                        .padding(16)
                        .background(cardSurface(accent: .purple))
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 36)
                }
            }
            .navigationTitle("Add \(player.name) to Teams")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var assignmentHero: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.purple, Color.accentColor],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                    .shadow(color: Color.purple.opacity(0.28), radius: 16, x: 0, y: 10)

                Image(systemName: "person.crop.circle.badge.plus")
                    .font(.system(size: 25, weight: .bold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text("Team Assignment")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .tracking(1.1)
                    .foregroundStyle(.purple)
                Text(player.name)
                    .font(.system(size: 27, weight: .black, design: .rounded))
                    .foregroundStyle(primaryText)
                    .lineLimit(1)
                Text("\(player.teams.count) active team\(player.teams.count == 1 ? "" : "s")")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(textMuted)
            }

            Spacer()
        }
        .padding(18)
        .background(cardSurface(accent: .purple))
    }

    private var emptyTeamsState: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.orange)
            Text("Create a team before assigning players.")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(textMuted)
            Spacer()
        }
        .padding(14)
        .background(fieldSurface)
    }

    private func assignmentRow(_ team: Team) -> some View {
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
