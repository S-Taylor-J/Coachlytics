//
//  CreateTeamSheet.swift
//  CoachingManager
//
//  Created by Taylor Santos on 13/02/2026.
//

import SwiftUI
import SwiftData

struct CreateTeamSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var teamName = ""
    @State private var selectedColor = Color.blue
    @State private var isAnimating = false
    
    var onTeamCreated: ((Team) -> Void)?
    
    private let teamColors: [Color] = [
        .blue, .purple, .pink, .red, .orange, .yellow, .green, .mint, .cyan, .indigo
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {
                        teamPreviewCard
                            .padding(.top, 12)

                        teamNameSection

                        tipsSection

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("Create Team")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createTeam()
                    }
                    .fontWeight(.semibold)
                    .disabled(teamName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
    
    // MARK: - Team Preview Card
    private var teamPreviewCard: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 92, height: 92)
                    .shadow(color: Color.accentColor.opacity(0.35), radius: 10, x: 0, y: 6)
                
                Image(systemName: "person.3.fill")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 6) {
                Text(teamName.isEmpty ? "Team Name" : teamName)
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundColor(teamName.isEmpty ? textMuted : primaryText)
                    .lineLimit(1)
                
                Text("0 players")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(cardSurface(accent: .accentColor))
    }
    
    // MARK: - Team Name Section
    private var teamNameSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Team Name", systemImage: "textformat")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)
            
            TextField("Enter team name", text: $teamName)
                .font(.system(size: 17, weight: .medium))
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(surfaceFill)
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(
                            teamName.isEmpty ? strokeColor : Color.accentColor,
                            lineWidth: teamName.isEmpty ? 1 : 2
                        )
                )
        }
    }
    
    // MARK: - Color Selection Section
    private var colorSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Team Color", systemImage: "paintpalette.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                ForEach(teamColors, id: \.self) { color in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedColor = color
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [color, color.opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 48, height: 48)
                                .shadow(color: color.opacity(0.4), radius: 4, x: 0, y: 2)
                            
                            if selectedColor == color {
                                Circle()
                                    .strokeBorder(Color.white, lineWidth: 3)
                                    .frame(width: 48, height: 48)
                                
                                Image(systemName: "checkmark")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
            )
        }
    }
    
    // MARK: - Tips Section
    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Getting Started", systemImage: "lightbulb.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)
            
            VStack(spacing: 0) {
                tipRow(
                    icon: "1.circle.fill",
                    title: "Create your team",
                    description: "Give your team a name",
                    iconColor: .blue
                )
                
                Divider()
                    .padding(.leading, 52)
                
                tipRow(
                    icon: "2.circle.fill",
                    title: "Add players",
                    description: "Add players with their numbers and positions",
                    iconColor: .green
                )
                
                Divider()
                    .padding(.leading, 52)
                
                tipRow(
                    icon: "3.circle.fill",
                    title: "Start coaching",
                    description: "Use the pitch view and track games",
                    iconColor: .purple
                )
            }
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(surfaceFill)
                    )
            )
        }
    }

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

    private var textMuted: Color {
        colorScheme == .dark ? Color.white.opacity(0.54) : Color(red: 0.45, green: 0.50, blue: 0.60)
    }

    private var surfaceFill: Color {
        colorScheme == .dark ? Color.white.opacity(0.065) : Color.white.opacity(0.86)
    }

    private var strokeColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.10) : Color(red: 0.55, green: 0.64, blue: 0.78).opacity(0.24)
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
    
    private func tipRow(icon: String, title: String, description: String, iconColor: Color) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(iconColor)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
    
    // MARK: - Actions
    private func createTeam() {
        let trimmed = teamName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        
        let team = Team(name: trimmed)
        context.insert(team)
        
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        
        onTeamCreated?(team)
        dismiss()
    }
}

// MARK: - Preview
#Preview {
    CreateTeamSheet()
        .modelContainer(for: [Team.self, Player.self], inMemory: true)
}
