//
//  TeamEdit.swift
//  CoachingManager
//
//  Created by Taylor Santos on 06/01/2026.
//
//

import Foundation
import SwiftUI
import SwiftData

// MARK: - Player Sort Options
enum PlayerSortOption: String, CaseIterable {
    case name = "Name"
    case number = "Number"
    case position = "Position"
    
    var icon: String {
        switch self {
        case .name: return "textformat"
        case .number: return "number"
        case .position: return "figure.run"
        }
    }
}

struct AddEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.colorScheme) private var colorScheme
    @Query(sort: \Team.name) private var teams: [Team]
    @Query(sort: \Player.name) private var players: [Player]
    @StateObject private var customOptionsManager = CustomOptionsManager.shared
    
    @State private var searchText = ""
    @State private var showAddSheet = false
    @State private var selectedTeam: Team?
    @State private var showCreateTeamSheet = false
    @State private var showTeamManagement = false
    @State private var playerToEdit: Player?
    @State private var showDeleteAlert = false
    @State private var playerToDelete: Player?
    @State private var offsetsToDelete: IndexSet?
    @State private var playerForTeamAssignment: Player?
    
    // Filter States
    @State private var selectedPositionFilter: String?
    @State private var selectedSkillFilter: String?
    @State private var sortOption: PlayerSortOption = .name
    @State private var sortAscending = true
    
    // Dynamic options from CustomOptionsManager
    private var positions: [String] {
        customOptionsManager.allPositions
    }
    
    private var skills: [String] {
        customOptionsManager.allSkills
    }
    
    private var hasActiveFilters: Bool {
        selectedTeam != nil || selectedPositionFilter != nil || selectedSkillFilter != nil || !searchText.isEmpty
    }
    
    var filteredPlayers: [Player] {
        var result = players
        
        // Filter by team
        if let team = selectedTeam {
            result = result.filter { player in
                team.players.contains { $0.id == player.id }
            }
        }
        
        // Filter by position
        if let position = selectedPositionFilter {
            result = result.filter { $0.positions.contains(position) }
        }
        
        // Filter by skill
        if let skill = selectedSkillFilter {
            result = result.filter { $0.skills.contains(skill) }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                String($0.number).contains(searchText)
            }
        }
        
        // Sort
        result = result.sorted { player1, player2 in
            let comparison: Bool
            switch sortOption {
            case .name:
                comparison = player1.name.localizedCompare(player2.name) == .orderedAscending
            case .number:
                comparison = player1.number < player2.number
            case .position:
                let pos1 = player1.positions.first ?? ""
                let pos2 = player2.positions.first ?? ""
                comparison = pos1 < pos2
            }
            return sortAscending ? comparison : !comparison
        }
        
        return result
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Team Header Section (when teams exist)
                if !teams.isEmpty {
                    teamHeaderSection
                }
                
                // Filter Bar
                playerFilterBar
                
                // Show onboarding when no teams exist
                if teams.isEmpty {
                    noTeamsOnboardingView
                } else if filteredPlayers.isEmpty {
                    emptyStateView
                } else {
                    List {
                        ForEach(filteredPlayers) { player in
                            Button {
                                playerToEdit = player
                            } label: {
                                PlayerRow(player: player)
                            }
                            .contextMenu {
                                Button {
                                    playerToEdit = player
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                
                                if let team = selectedTeam,
                                    team.players.contains(where: { $0.id == player.id }) {
                                    Button {
                                        removePlayerFromTeam(player, team: team)
                                    } label: {
                                        Label("Remove from Team", systemImage: "person.fill.xmark")
                                    }
                                }
                                
                                Button {
                                    playerForTeamAssignment = player
                                } label: {
                                    Label("Add to Team", systemImage: "person.fill.badge.plus")
                                }
                                
                                Button(role: .destructive) {
                                    playerToDelete = player
                                    showDeleteAlert = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                        .onDelete { offsets in
                            offsetsToDelete = offsets
                            showDeleteAlert = true
                        }
                    }
                    .listStyle(.plain)
                    .contentMargins(.bottom, 50, for: .scrollContent)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Players")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        if teams.isEmpty {
                            Button {
                                showCreateTeamSheet = true
                            } label: {
                                Image(systemName: "person.3.fill")
                                    .font(.system(size: 18))
                                    .symbolRenderingMode(.hierarchical)
                            }
                        }
                        
                        if !teams.isEmpty {
                            Button {
                                showAddSheet = true
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 22))
                                    .symbolRenderingMode(.hierarchical)
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddPlayerSheet(selectedTeam: selectedTeam)
            }
            .sheet(item: $playerToEdit) { player in
                EditPlayerSheet(player: player)
            }
            .sheet(item: $playerForTeamAssignment) { player in
                TeamAssignmentSheet(player: player, selectedTeam: $selectedTeam)
            }
            .sheet(isPresented: $showCreateTeamSheet) {
                CreateTeamSheet { newTeam in
                    selectedTeam = newTeam
                }
            }
            .sheet(isPresented: $showTeamManagement) {
                TeamManagementSheet(teams: teams, selectedTeam: $selectedTeam)
            }
            .alert("Delete Player", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) {
                    playerToDelete = nil
                    offsetsToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let player = playerToDelete {
                        deletePlayer(player)
                        playerToDelete = nil
                    } else if let offsets = offsetsToDelete {
                        deletePlayerAtIndex(at: offsets)
                        offsetsToDelete = nil
                    }
                }
            } message: {
                Text("This action cannot be undone.")
            }
        }
    }
    
    // MARK: - Filter Bar
    private var playerFilterBar: some View {
        VStack(spacing: 0) {
            // Search Bar
            HStack(spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    TextField("Search players...", text: $searchText)
                        .font(.system(size: 15))
                    
                    if !searchText.isEmpty {
                        Button {
                            withAnimation(.easeOut(duration: 0.15)) {
                                searchText = ""
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(Color(.systemGray3))
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.systemGray5).opacity(0.5))
                )
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 12)
            
            // Filter Chips Row
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // Sort Menu
                    Menu {
                        ForEach(PlayerSortOption.allCases, id: \.self) { option in
                            Button {
                                withAnimation { sortOption = option }
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            } label: {
                                Label(option.rawValue, systemImage: sortOption == option ? "checkmark" : option.icon)
                            }
                        }
                        
                        Divider()
                        
                        Button {
                            withAnimation { sortAscending.toggle() }
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        } label: {
                            Label(
                                sortAscending ? "Ascending" : "Descending",
                                systemImage: sortAscending ? "arrow.up" : "arrow.down"
                            )
                        }
                    } label: {
                        PlayerFilterChip(
                            label: sortOption.rawValue,
                            icon: sortAscending ? "arrow.up" : "arrow.down",
                            isActive: false,
                            style: .secondary
                        )
                    }
                    
                    // Team Filter Menu
                    Menu {
                        Button {
                            withAnimation { selectedTeam = nil }
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        } label: {
                            Label("All Teams", systemImage: selectedTeam == nil ? "checkmark" : "")
                        }
                        
                        Divider()
                        
                        ForEach(teams) { team in
                            Button {
                                withAnimation { selectedTeam = team }
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            } label: {
                                Label(team.name, systemImage: selectedTeam?.id == team.id ? "checkmark" : "")
                            }
                        }
                        
                        Divider()
                        
                        Button {
                            showCreateTeamSheet = true
                        } label: {
                            Label("Create Team...", systemImage: "plus")
                        }
                    } label: {
                        PlayerFilterChip(
                            label: selectedTeam?.name ?? "All Teams",
                            icon: "person.3.fill",
                            isActive: selectedTeam != nil,
                            style: selectedTeam != nil ? .colored(.purple) : .secondary
                        )
                    }
                    
                    // Position Filter Menu
                    Menu {
                        Button {
                            withAnimation { selectedPositionFilter = nil }
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        } label: {
                            Label("All Positions", systemImage: selectedPositionFilter == nil ? "checkmark" : "")
                        }
                        
                        Divider()
                        
                        ForEach(positions, id: \.self) { position in
                            Button {
                                withAnimation { selectedPositionFilter = position }
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            } label: {
                                Label(position, systemImage: selectedPositionFilter == position ? "checkmark" : "")
                            }
                        }
                    } label: {
                        PlayerFilterChip(
                            label: selectedPositionFilter ?? "Position",
                            icon: "figure.run",
                            isActive: selectedPositionFilter != nil,
                            style: selectedPositionFilter != nil ? .colored(.blue) : .secondary
                        )
                    }
                    
                    // Skill Filter Menu
                    Menu {
                        Button {
                            withAnimation { selectedSkillFilter = nil }
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        } label: {
                            Label("All Skills", systemImage: selectedSkillFilter == nil ? "checkmark" : "")
                        }
                        
                        Divider()
                        
                        ForEach(skills, id: \.self) { skill in
                            Button {
                                withAnimation { selectedSkillFilter = skill }
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            } label: {
                                Label(skill, systemImage: selectedSkillFilter == skill ? "checkmark" : "")
                            }
                        }
                    } label: {
                        PlayerFilterChip(
                            label: selectedSkillFilter ?? "Skill",
                            icon: "star.fill",
                            isActive: selectedSkillFilter != nil,
                            style: selectedSkillFilter != nil ? .colored(.orange) : .secondary
                        )
                    }
                    
                    // Clear filters
                    if hasActiveFilters {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedTeam = nil
                                selectedPositionFilter = nil
                                selectedSkillFilter = nil
                                searchText = ""
                            }
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(Color(.systemGray3))
                        }
                        .buttonStyle(.plain)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
        }
        .background(Color(.systemBackground))
    }
    
    // MARK: - Team Header Section
    private var teamHeaderSection: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                // Team Badge
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.purple, .purple.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 52, height: 52)
                        .shadow(color: .purple.opacity(0.3), radius: 6, x: 0, y: 3)
                    
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    if let team = selectedTeam {
                        Text(team.name)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                        
                        Text("\(team.players.count) player\(team.players.count == 1 ? "" : "s")")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                    } else {
                        Text("All Teams")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                        
                        Text("\(teams.count) team\(teams.count == 1 ? "" : "s") • \(players.count) player\(players.count == 1 ? "" : "s")")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Team Management Button - more intuitive
                Button {
                    showTeamManagement = true
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.purple.opacity(0.12))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.purple)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color(.systemBackground))
            
            Divider()
        }
    }
    
    // MARK: - No Teams Onboarding View
    private var noTeamsOnboardingView: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer()
                    .frame(height: 40)
                
                // Welcome Icon
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.purple.opacity(0.2), Color.purple.opacity(0)],
                                center: .center,
                                startRadius: 40,
                                endRadius: 100
                            )
                        )
                        .frame(width: 200, height: 200)
                    
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.purple, .purple.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .shadow(color: .purple.opacity(0.4), radius: 16, x: 0, y: 8)
                    
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 40, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                // Welcome Text
                VStack(spacing: 10) {
                    Text("Welcome to CoachingManager")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                    
                    Text("Get started by creating your first team.\nYou can add players and start managing\nyour coaching sessions.")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .padding(.horizontal, 32)
                
                // Create Team Button
                Button {
                    showCreateTeamSheet = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                        Text("Create Your First Team")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [.purple, .purple.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: .purple.opacity(0.4), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal, 32)
                .padding(.top, 8)
                
                // Feature Cards
                VStack(spacing: 12) {
                    featureCard(
                        icon: "person.badge.plus",
                        title: "Add Players",
                        description: "Track player positions, skills, and jersey numbers",
                        color: .blue
                    )
                    
                    featureCard(
                        icon: "sportscourt.fill",
                        title: "Pitch Management",
                        description: "Visualize formations and player positions",
                        color: .green
                    )
                    
                    featureCard(
                        icon: "chart.bar.fill",
                        title: "Track Games",
                        description: "Record game events and analyze performance",
                        color: .orange
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                Spacer()
                    .frame(height: 100)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
    
    private func featureCard(icon: String, title: String, description: String, color: Color) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.05), radius: 6, x: 0, y: 2)
        )
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: hasActiveFilters ? "line.3.horizontal.decrease.circle" : "person.crop.circle")
                .font(.system(size: 44))
                .foregroundColor(Color(.systemGray3))
            
            VStack(spacing: 6) {
                Text(hasActiveFilters ? "No players found" : "No players yet")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(hasActiveFilters ? "Try adjusting your filters" : "Add a player to get started")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if hasActiveFilters {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTeam = nil
                        selectedPositionFilter = nil
                        selectedSkillFilter = nil
                        searchText = ""
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    Text("Clear Filters")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.blue)
                }
                .padding(.top, 4)
            } else if selectedTeam == nil {
                Button {
                    showAddSheet = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18))
                        Text("Add Player")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundColor(.blue)
                }
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
    
    private func PlayerRow(player: Player) -> some View {
        HStack(spacing: 14) {
            // Player number badge
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.15), Color.blue.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                
                Text("\(player.number)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.blue)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                // Player name
                Text(player.name)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                
                // Position & Skills chips row
                if !player.positions.isEmpty || !player.skills.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            // Position chips
                            ForEach(player.positions.prefix(2), id: \.self) { position in
                                HStack(spacing: 4) {
                                    Image(systemName: "figure.run")
                                        .font(.system(size: 9, weight: .semibold))
                                    Text(position)
                                        .font(.system(size: 11, weight: .medium, design: .rounded))
                                }
                                .foregroundStyle(Color.blue)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color.blue.opacity(0.12))
                                )
                            }
                            
                            // Show +N if more positions
                            if player.positions.count > 2 {
                                Text("+\(player.positions.count - 2)")
                                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                                    .foregroundStyle(Color.blue.opacity(0.7))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .strokeBorder(Color.blue.opacity(0.3), lineWidth: 1)
                                    )
                            }
                            
                            // Skill chips
                            ForEach(player.skills.prefix(2), id: \.self) { skill in
                                HStack(spacing: 4) {
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 8, weight: .semibold))
                                    Text(skill)
                                        .font(.system(size: 11, weight: .medium, design: .rounded))
                                }
                                .foregroundStyle(Color.orange)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color.orange.opacity(0.12))
                                )
                            }
                            
                            // Show +N if more skills
                            if player.skills.count > 2 {
                                Text("+\(player.skills.count - 2)")
                                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                                    .foregroundStyle(Color.orange.opacity(0.7))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .strokeBorder(Color.orange.opacity(0.3), lineWidth: 1)
                                    )
                            }
                        }
                    }
                    .frame(height: 24)
                }
                
                // Team badges
                if !player.teams.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "flag.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                        
                        Text(player.teams.prefix(2).map { $0.name }.joined(separator: " · "))
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                        
                        if player.teams.count > 2 {
                            Text("+\(player.teams.count - 2)")
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }
            
            Spacer(minLength: 8)
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.quaternary)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
    
    private func deletePlayerAtIndex(at offsets: IndexSet) {
        for index in offsets {
            let player = filteredPlayers[index]
            context.delete(player)
        }
    }
    
    private func deletePlayer(_ player: Player) {
        context.delete(player)
    }
    
    private func removePlayerFromTeam(_ player: Player, team: Team) {
        if let index = team.players.firstIndex(where: { $0.id == player.id }) {
            team.players.remove(at: index)
        }
        if let index = player.teams.firstIndex(where: { $0.id == team.id }) {
            player.teams.remove(at: index)
        }
    }
}

#Preview {
    AddEditView()
        .modelContainer(for: [Player.self, Team.self], inMemory: true)
}

// MARK: - Player Filter Chip Style
enum PlayerFilterChipStyle {
    case secondary
    case active
    case colored(Color)
    
    var backgroundColor: Color {
        switch self {
        case .secondary:
            return Color(.systemGray5)
        case .active:
            return Color.blue
        case .colored(let color):
            return color
        }
    }
    
    var foregroundColor: Color {
        switch self {
        case .secondary:
            return .primary
        case .active, .colored:
            return .white
        }
    }
}

// MARK: - Player Filter Chip
struct PlayerFilterChip: View {
    let label: String
    let icon: String?
    let isActive: Bool
    let style: PlayerFilterChipStyle
    
    init(label: String, icon: String? = nil, isActive: Bool = false, style: PlayerFilterChipStyle = .secondary) {
        self.label = label
        self.icon = icon
        self.isActive = isActive
        self.style = style
    }
    
    var body: some View {
        HStack(spacing: 5) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .medium))
            }
            
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .lineLimit(1)
            
            if case .secondary = style {
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(style.backgroundColor)
        )
        .foregroundColor(style.foregroundColor)
        .overlay(
            Capsule()
                .strokeBorder(Color(.systemGray4).opacity(style.backgroundColor == Color(.systemGray5) ? 0.5 : 0), lineWidth: 0.5)
        )
    }
}

