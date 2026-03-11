//
//  GameListView.swift
//  CoachingManager
//
//  Created by Taylor Santos on 07/01/2026.
//

import SwiftUI
import SwiftData

// MARK: - Filter Enums
enum GameSortOption: String, CaseIterable {
    case date = "Date"
    case team = "Team"
    case result = "Result"
    
    var icon: String {
        switch self {
        case .date: return "calendar"
        case .team: return "person.3.fill"
        case .result: return "trophy.fill"
        }
    }
}

enum GameResultFilter: String, CaseIterable {
    case all = "All"
    case wins = "Wins"
    case losses = "Losses"
    case draws = "Draws"
    
    var icon: String {
        switch self {
        case .all: return "list.bullet"
        case .wins: return "hand.thumbsup.fill"
        case .losses: return "hand.thumbsdown.fill"
        case .draws: return "equal.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .all: return .gray
        case .wins: return .green
        case .losses: return .red
        case .draws: return .orange
        }
    }
}

// MARK: - Game List View
struct GameListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Query(sort: \Game.date, order: .reverse) private var games: [Game]
    @Query(sort: \Team.name) private var teams: [Team]
    
    @State private var showNewGameSheet = false
    @State private var selectedGame: Game?
    @State private var showDeleteAlert = false
    @State private var gameToDelete: Game?
    @State private var offsetsToDelete: IndexSet?
    
    // Filter States
    @State private var selectedTeamFilter: Team?
    @State private var selectedResultFilter: GameResultFilter = .all
    @State private var sortOption: GameSortOption = .date
    @State private var sortAscending = false
    @State private var searchText = ""
    @State private var isSearchFocused = false
    
    // Filtered and sorted games
    private var filteredGames: [Game] {
        var result = games
        
        // Filter by search text
        if !searchText.isEmpty {
            result = result.filter {
                $0.myTeamName.localizedCaseInsensitiveContains(searchText) ||
                $0.opponentName.localizedCaseInsensitiveContains(searchText) ||
                $0.location.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Filter by team
        if let team = selectedTeamFilter {
            result = result.filter { $0.myTeamId == team.id }
        }
        
        // Filter by result
        switch selectedResultFilter {
        case .all:
            break
        case .wins:
            result = result.filter { $0.isCompleted && $0.myTeamScore > $0.opponentScore }
        case .losses:
            result = result.filter { $0.isCompleted && $0.myTeamScore < $0.opponentScore }
        case .draws:
            result = result.filter { $0.isCompleted && $0.myTeamScore == $0.opponentScore }
        }
        
        // Sort
        result = result.sorted { game1, game2 in
            let comparison: Bool
            switch sortOption {
            case .date:
                comparison = game1.date < game2.date
            case .team:
                comparison = game1.myTeamName < game2.myTeamName
            case .result:
                let score1 = game1.myTeamScore - game1.opponentScore
                let score2 = game2.myTeamScore - game2.opponentScore
                comparison = score1 < score2
            }
            return sortAscending ? comparison : !comparison
        }
        
        return result
    }
    
    private var hasActiveFilters: Bool {
        selectedTeamFilter != nil || selectedResultFilter != .all || !searchText.isEmpty
    }
    
    private var activeFilterCount: Int {
        var count = 0
        if selectedTeamFilter != nil { count += 1 }
        if selectedResultFilter != .all { count += 1 }
        if !searchText.isEmpty { count += 1 }
        return count
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Compact Filter Bar
                filterBarCompact
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // Scheduled Games Section
                        if !scheduledGames.isEmpty && !hasActiveFilters {
                            scheduledGamesSection
                        }
                        
                        // Active Games Section
                        if !activeGames.isEmpty && !hasActiveFilters {
                            activeGamesSection
                        }
                        
                        // All Games Section
                        allGamesSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 100)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Games")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        showNewGameSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .symbolRenderingMode(.hierarchical)
                    }
                }
            }
            .sheet(isPresented: $showNewGameSheet) {
                NewGameSheet(teams: teams) { game in
                    modelContext.insert(game)
                    try? modelContext.save()
                    selectedGame = game
                }
            }
            .navigationDestination(item: $selectedGame) { game in
                GameDetailView(game: game)
            }
        }
    }
    
    // MARK: - Compact Filter Bar
    private var filterBarCompact: some View {
        VStack(spacing: 0) {
            // Search Bar
            HStack(spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    TextField("Search teams, locations...", text: $searchText)
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
                        ForEach(GameSortOption.allCases, id: \.self) { option in
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
                                sortAscending ? "Oldest First" : "Newest First",
                                systemImage: sortAscending ? "arrow.up" : "arrow.down"
                            )
                        }
                    } label: {
                        FilterChip(
                            label: sortOption.rawValue,
                            icon: sortAscending ? "arrow.up" : "arrow.down",
                            isActive: false,
                            style: .secondary
                        )
                    }
                    
                    // Team Filter Menu
                    Menu {
                        Button {
                            withAnimation { selectedTeamFilter = nil }
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        } label: {
                            Label("All Teams", systemImage: selectedTeamFilter == nil ? "checkmark" : "")
                        }
                        
                        Divider()
                        
                        ForEach(teams) { team in
                            Button {
                                withAnimation { selectedTeamFilter = team }
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            } label: {
                                Label(team.name, systemImage: selectedTeamFilter?.id == team.id ? "checkmark" : "")
                            }
                        }
                    } label: {
                        FilterChip(
                            label: selectedTeamFilter?.name ?? "All Teams",
                            icon: "person.3.fill",
                            isActive: selectedTeamFilter != nil,
                            style: selectedTeamFilter != nil ? .active : .secondary
                        )
                    }
                    
                    // Result Filter Chips
                    ForEach(GameResultFilter.allCases, id: \.self) { result in
                        if result != .all {
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    if selectedResultFilter == result {
                                        selectedResultFilter = .all
                                    } else {
                                        selectedResultFilter = result
                                    }
                                }
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            } label: {
                                FilterChip(
                                    label: result.rawValue,
                                    icon: result.icon,
                                    isActive: selectedResultFilter == result,
                                    style: selectedResultFilter == result ? .colored(result.color) : .secondary
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    // Clear filters
                    if hasActiveFilters {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedTeamFilter = nil
                                selectedResultFilter = .all
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
    };
    // MARK: - Active Games\n
    private var scheduledGames: [Game] {
        games.filter { $0.isScheduled }.sorted { $0.date < $1.date }
    }
    
    private var activeGames: [Game] {
        games.filter { !$0.isCompleted && !$0.isScheduled }
    }
    private var filteredCompletedGames: [Game] {
        filteredGames.filter { $0.isCompleted }
    }
    
    // MARK: - Active Games Section
    private var activeGamesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                Text("In Progress")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
                
                Spacer()
            }
            .padding(.horizontal, 4)
            
            ForEach(activeGames) { game in
                ActiveGameCard(game: game) {
                    selectedGame = game
                }
            }
        }
    }
    
    // MARK: - Scheduled Games Section
    private var scheduledGamesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                Text("Scheduled")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Image(systemName: "calendar.badge.clock")
                    .foregroundColor(.orange)
                    .font(.system(size: 14, weight: .semibold))
                
                Spacer()
                
                Text("\(scheduledGames.count)")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.orange.opacity(0.15))
                    )
            }
            .padding(.horizontal, 4)
            
            ForEach(scheduledGames) { game in
                ScheduledGameCard(game: game) {
                    selectedGame = game
                }
            }
        }
    }
    
    // MARK: - All Games Section
    private var allGamesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Header
            HStack(alignment: .center) {
                Text("History")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Spacer()
                
                if hasActiveFilters {
                    Text("\(filteredCompletedGames.count) of \(games.filter { $0.isCompleted }.count)")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color(.systemGray5))
                        )
                } else if !filteredCompletedGames.isEmpty {
                    Text("\(filteredCompletedGames.count)")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color(.systemGray5))
                        )
                }
            }
            .padding(.horizontal, 4)
            
            if filteredCompletedGames.isEmpty {
                if hasActiveFilters {
                    noResultsCard
                } else {
                    emptyStateCard
                }
            } else {
                List {
                    ForEach(filteredCompletedGames) { game in
                        Button {
                            selectedGame = game
                        } label: {
                            GameHistoryRow(game: game)
                        }
                        .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                        .listRowSeparator(.hidden)
                        .contextMenu {
                            Button(role: .destructive) {
                                gameToDelete = game
                                showDeleteAlert = true
                            } label: {
                                Label("Delete Game", systemImage: "trash")
                            }
                        }
                    }
                    .onDelete { offsets in
                        offsetsToDelete = offsets
                        showDeleteAlert = true
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .contentMargins(.top, 8, for: .scrollContent)
                .contentMargins(.bottom, 100, for: .scrollContent)
                .frame(minHeight: CGFloat(filteredCompletedGames.count) * 78 + 108)
            }
        }
        .alert("Delete Game", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {
                offsetsToDelete = nil
                gameToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let game = gameToDelete {
                    deleteGame(game)
                } else if let offsets = offsetsToDelete {
                    for index in offsets {
                        let game = filteredCompletedGames[index]
                        deleteGame(game)
                    }
                }
                offsetsToDelete = nil
                gameToDelete = nil
            }
        } message: {
            Text("Are you sure you want to delete this game? This action cannot be undone.")
        }
    }
    
    // MARK: - No Results Card
    private var noResultsCard: some View {
        VStack(spacing: 20) {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .font(.system(size: 44))
                .foregroundColor(Color(.systemGray3))
            
            VStack(spacing: 6) {
                Text("No games found")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text("Try adjusting your search or filters")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedTeamFilter = nil
                    selectedResultFilter = .all
                    searchText = ""
                }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } label: {
                Text("Clear Filters")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.blue)
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .padding(.horizontal, 24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
    
    // MARK: - Empty State
    private var emptyStateCard: some View {
        VStack(spacing: 20) {
            Image(systemName: "sportscourt")
                .font(.system(size: 44))
                .foregroundColor(Color(.systemGray3))
            
            VStack(spacing: 6) {
                Text("No games yet")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text("Start tracking your games by\ntapping the + button")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .padding(.horizontal, 24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
    
    private func deleteGame(_ game: Game) {
        modelContext.delete(game)
        try? modelContext.save()
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}

// MARK: - Active Game Card
struct ActiveGameCard: View {
    let game: Game
    let onTap: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Teams and Score
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(game.myTeamName)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.red)
                        Text("vs")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        Text(game.opponentName)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    // Score
                    VStack(spacing: 2) {
                        Text("\(game.myTeamScore)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.red)
                        Text("-")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.secondary)
                        Text("\(game.opponentScore)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.blue)
                    }
                }
                
                Divider()
                
                // Status Row
                HStack {
                    // Quarter
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 10))
                        Text("Q\(game.currentQuarter)")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.orange)
                    
                    Spacer()
                    
                    // Location
                    if !game.location.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 10))
                            Text(game.location)
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Continue button
                    HStack(spacing: 4) {
                        Text("Continue")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundColor(.green)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 8, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.green.opacity(0.3), lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Scheduled Game Card
struct ScheduledGameCard: View {
    let game: Game
    let onTap: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: game.date)
    }
    
    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: game.date)
    }
    
    private var daysUntil: String {
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: Date()), to: calendar.startOfDay(for: game.date)).day ?? 0
        if days == 0 {
            return "Today"
        } else if days == 1 {
            return "Tomorrow"
        } else {
            return "In \(days) days"
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Teams
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(game.myTeamName)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.red)
                        Text("vs")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        Text(game.opponentName)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    // Scheduled badge
                    VStack(spacing: 4) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 28))
                            .foregroundColor(.orange)
                        Text(daysUntil)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(.orange)
                    }
                }
                
                Divider()
                
                // Info Row
                HStack {
                    // Date & Time
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 10))
                        Text(formattedDate)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.orange)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 10))
                        Text(formattedTime)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.orange)
                    
                    Spacer()
                    
                    // Location
                    if !game.location.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 10))
                            Text(game.location)
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // View button
                    HStack(spacing: 4) {
                        Text("View")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundColor(.orange)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 8, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.orange.opacity(0.3), lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Game History Row
struct GameHistoryRow: View {
    let game: Game
    
    var body: some View {
        HStack(spacing: 16) {
            // Date badge
            VStack(spacing: 2) {
                Text(game.shortDate)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)
            }
            .frame(width: 50)
            
            // Teams
            VStack(alignment: .leading, spacing: 4) {
                Text("\(game.myTeamName) vs \(game.opponentName)")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                
                if !game.location.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 9))
                        Text(game.location)
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Score
            VStack(alignment: .trailing, spacing: 4) {
                Text(game.scoreString)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(game.resultString)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(game.resultColor)
            }
            .padding(.trailing, 8)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - New Game Sheet
struct NewGameSheet: View {
    let teams: [Team]
    let onCreate: (Game) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var selectedTeam: Team?
    @State private var opponentName: String = ""
    @State private var location: String = ""
    @State private var scheduledDate: Date = Date()
    @State private var isScheduledGame: Bool = false
    @State private var quarters: Int
    @State private var quarterMinutes: Int
    @State private var quarterSeconds: Int
    
    // Load defaults from saved game settings
    init(teams: [Team], onCreate: @escaping (Game) -> Void) {
        self.teams = teams
        self.onCreate = onCreate
        
        // Load settings from UserDefaults (stored as String by AppStorage)
        if let settingsString = UserDefaults.standard.string(forKey: "gameSettingsData"),
           let data = settingsString.data(using: .utf8),
           let settings = try? JSONDecoder().decode(GameSettings.self, from: data) {
            _quarters = State(initialValue: settings.quarters)
            // Convert stored seconds to minutes:seconds for display
            let totalSeconds = settings.quarterDurationInSeconds
            _quarterMinutes = State(initialValue: totalSeconds / 60)
            _quarterSeconds = State(initialValue: totalSeconds % 60)
        } else {
            _quarters = State(initialValue: 4)
            _quarterMinutes = State(initialValue: 15)
            _quarterSeconds = State(initialValue: 0)
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // My Team Selection
                    myTeamSection
                    
                    // Opponent Name
                    opponentSection
                    
                    // Location
                    locationSection
                    
                    // Schedule Date
                    scheduleDateSection
                    
                    // Game Settings
                    gameSettingsSection
                }
                .padding(20)
            }
            .background(
                LinearGradient(
                    colors: colorScheme == .dark
                        ? [Color(.systemBackground), Color(.systemGray6)]
                        : [Color(.systemGray6).opacity(0.3), Color(.systemBackground)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationTitle("New Game")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createGame()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .disabled(selectedTeam == nil || opponentName.isEmpty)
                }
            }
        }
    }
    
    // MARK: - My Team Section
    private var myTeamSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "house.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.red)
                Text("My Team")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
            }
            
            if teams.isEmpty {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Create a team first in the Team tab")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(16)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.orange.opacity(0.1))
                )
            } else {
                VStack(spacing: 8) {
                    ForEach(teams) { team in
                        TeamSelectionRow(
                            team: team,
                            isSelected: selectedTeam?.id == team.id
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedTeam = team
                            }
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 8, x: 0, y: 4)
        )
    }
    
    // MARK: - Opponent Section
    private var opponentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "figure.run")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.blue)
                Text("Opponent")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
            }
            
            TextField("Enter opponent team name", text: $opponentName)
                .font(.system(size: 15))
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 8, x: 0, y: 4)
        )
    }
    
    // MARK: - Location Section
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "location.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.green)
                Text("Location")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                
                Spacer()
                
                Text("Optional")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            TextField("Enter game location", text: $location)
                .font(.system(size: 15))
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 8, x: 0, y: 4)
        )
    }
    
    // MARK: - Schedule Date Section
    private var scheduleDateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.orange)
                Text("Schedule")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                
                Spacer()
                
                Toggle("", isOn: $isScheduledGame)
                    .labelsHidden()
            }
            
            if isScheduledGame {
                VStack(spacing: 12) {
                    DatePicker(
                        "Game Date & Time",
                        selection: $scheduledDate,
                        in: Date()...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.graphical)
                    .tint(.orange)
                    
                    HStack {
                        Image(systemName: "info.circle")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        Text("Scheduled games will appear on your calendar")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            } else {
                Text("Toggle to schedule this game for a future date")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 8, x: 0, y: 4)
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isScheduledGame)
    }
    
    // MARK: - Game Settings Section
    private var gameSettingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.purple)
                Text("Game Settings")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
            }
            
            VStack(spacing: 16) {
                // Quarters
                HStack {
                    Text("Quarters")
                        .font(.system(size: 14, weight: .medium))
                    Spacer()
                    Picker("Quarters", selection: $quarters) {
                        ForEach([2, 4], id: \.self) { num in
                            Text("\(num)").tag(num)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 120)
                }
                
                Divider()
                
                // Quarter Duration - Custom Input
                VStack(alignment: .leading, spacing: 10) {
                    Text("Quarter Duration")
                        .font(.system(size: 14, weight: .medium))
                    
                    HStack(spacing: 12) {
                        // Minutes input
                        VStack(spacing: 4) {
                            Text("Minutes")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 8) {
                                Button {
                                    if quarterMinutes > 0 {
                                        quarterMinutes -= 1
                                    }
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.system(size: 22))
                                        .foregroundColor(quarterMinutes > 0 ? .blue : .gray.opacity(0.4))
                                }
                                .disabled(quarterMinutes <= 0)
                                
                                Text("\(quarterMinutes)")
                                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                                    .frame(width: 44)
                                
                                Button {
                                    if quarterMinutes < 60 {
                                        quarterMinutes += 1
                                    }
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 22))
                                        .foregroundColor(quarterMinutes < 60 ? .blue : .gray.opacity(0.4))
                                }
                                .disabled(quarterMinutes >= 60)
                            }
                        }
                        
                        Text(":")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.secondary)
                        
                        // Seconds input
                        VStack(spacing: 4) {
                            Text("Seconds")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 8) {
                                Button {
                                    if quarterSeconds > 0 {
                                        quarterSeconds -= 5
                                    } else if quarterMinutes > 0 {
                                        quarterMinutes -= 1
                                        quarterSeconds = 55
                                    }
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.system(size: 22))
                                        .foregroundColor((quarterSeconds > 0 || quarterMinutes > 0) ? .blue : .gray.opacity(0.4))
                                }
                                .disabled(quarterSeconds <= 0 && quarterMinutes <= 0)
                                
                                Text(String(format: "%02d", quarterSeconds))
                                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                                    .frame(width: 44)
                                
                                Button {
                                    if quarterSeconds < 55 {
                                        quarterSeconds += 5
                                    } else if quarterMinutes < 60 {
                                        quarterSeconds = 0
                                        quarterMinutes += 1
                                    }
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 22))
                                        .foregroundColor((quarterSeconds < 55 || quarterMinutes < 60) ? .blue : .gray.opacity(0.4))
                                }
                                .disabled(quarterMinutes >= 60 && quarterSeconds >= 55)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Total time display
                    Text("Total: \(quarterMinutes):\(String(format: "%02d", quarterSeconds)) per quarter")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 8, x: 0, y: 4)
        )
    }
    
    private func createGame() {
        guard let team = selectedTeam else { return }
        
        // Calculate total duration in seconds
        let totalDurationSeconds = (quarterMinutes * 60) + quarterSeconds
        
        let game = Game(
            myTeamId: team.id,
            myTeamName: team.name,
            opponentName: opponentName,
            location: location,
            quarters: quarters,
            quarterDuration: totalDurationSeconds,
            scheduledDate: isScheduledGame ? scheduledDate : nil
        )
        
        onCreate(game)
        dismiss()
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}

// MARK: - Edit Game Sheet
struct EditGameSheet: View {
    @Bindable var game: Game
    let teams: [Team]
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var opponentName: String = ""
    @State private var location: String = ""
    @State private var scheduledDate: Date = Date()
    @State private var isScheduledGame: Bool = false
    @State private var quarters: Int = 4
    @State private var quarterMinutes: Int = 15
    @State private var quarterSeconds: Int = 0
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Teams Display
                    teamsSection
                    
                    // Opponent Name
                    opponentSection
                    
                    // Location
                    locationSection
                    
                    // Schedule Date
                    scheduleDateSection
                    
                    // Game Settings (only if game hasn't started)
                    if !game.isGameActive && !game.isCompleted {
                        gameSettingsSection
                    }
                }
                .padding(20)
            }
            .background(
                LinearGradient(
                    colors: colorScheme == .dark
                        ? [Color(.systemBackground), Color(.systemGray6)]
                        : [Color(.systemGray6).opacity(0.3), Color(.systemBackground)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Edit Game")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .disabled(opponentName.isEmpty)
                }
            }
            .onAppear {
                loadCurrentValues()
            }
        }
    }
    
    // MARK: - Teams Section
    private var teamsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sportscourt.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.blue)
                Text("Match")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
            }
            
            HStack(spacing: 16) {
                // My Team
                VStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 48, height: 48)
                        Text(String(game.myTeamName.prefix(2)).uppercased())
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    Text(game.myTeamName)
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
                
                Text("vs")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.secondary)
                
                // Opponent
                VStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 48, height: 48)
                        Text(String(opponentName.prefix(2)).uppercased())
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    Text(opponentName.isEmpty ? "Opponent" : opponentName)
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(1)
                        .foregroundColor(opponentName.isEmpty ? .secondary : .primary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 8, x: 0, y: 4)
        )
    }
    
    // MARK: - Opponent Section
    private var opponentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "figure.run")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.blue)
                Text("Opponent Name")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
            }
            
            TextField("Enter opponent team name", text: $opponentName)
                .font(.system(size: 15))
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 8, x: 0, y: 4)
        )
    }
    
    // MARK: - Location Section
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "location.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.green)
                Text("Location")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                
                Spacer()
                
                Text("Optional")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            TextField("Enter game location", text: $location)
                .font(.system(size: 15))
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 8, x: 0, y: 4)
        )
    }
    
    // MARK: - Schedule Date Section
    private var scheduleDateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.orange)
                Text("Schedule")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                
                Spacer()
                
                if !game.isGameActive && !game.isCompleted {
                    Toggle("", isOn: $isScheduledGame)
                        .labelsHidden()
                }
            }
            
            if game.isGameActive || game.isCompleted {
                HStack {
                    Image(systemName: "info.circle")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Text("Schedule cannot be changed after game has started")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            } else if isScheduledGame {
                VStack(spacing: 12) {
                    DatePicker(
                        "Game Date & Time",
                        selection: $scheduledDate,
                        in: Date()...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.graphical)
                    .tint(.orange)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            } else {
                Text("Toggle to schedule this game for a future date")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 8, x: 0, y: 4)
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isScheduledGame)
    }
    
    // MARK: - Game Settings Section
    private var gameSettingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.purple)
                Text("Game Settings")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
            }
            
            VStack(spacing: 16) {
                // Quarters
                HStack {
                    Text("Quarters")
                        .font(.system(size: 14, weight: .medium))
                    Spacer()
                    Picker("Quarters", selection: $quarters) {
                        ForEach([2, 4], id: \.self) { num in
                            Text("\(num)").tag(num)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 120)
                }
                
                Divider()
                
                // Quarter Duration
                VStack(alignment: .leading, spacing: 10) {
                    Text("Quarter Duration")
                        .font(.system(size: 14, weight: .medium))
                    
                    HStack(spacing: 12) {
                        VStack(spacing: 4) {
                            Text("Minutes")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            Stepper("\(quarterMinutes)", value: $quarterMinutes, in: 0...60)
                                .labelsHidden()
                            
                            Text("\(quarterMinutes)")
                                .font(.system(size: 18, weight: .bold, design: .monospaced))
                        }
                        
                        Text(":")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.secondary)
                        
                        VStack(spacing: 4) {
                            Text("Seconds")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            Stepper("\(quarterSeconds)", value: $quarterSeconds, in: 0...55, step: 5)
                                .labelsHidden()
                            
                            Text(String(format: "%02d", quarterSeconds))
                                .font(.system(size: 18, weight: .bold, design: .monospaced))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    Text("Total: \(quarterMinutes):\(String(format: "%02d", quarterSeconds)) per quarter")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 8, x: 0, y: 4)
        )
    }
    
    private func loadCurrentValues() {
        opponentName = game.opponentName
        location = game.location
        scheduledDate = game.date
        isScheduledGame = game.isScheduled
        quarters = game.quarters
        let totalSeconds = game.quarterDurationInSeconds
        quarterMinutes = totalSeconds / 60
        quarterSeconds = totalSeconds % 60
    }
    
    private func saveChanges() {
        game.opponentName = opponentName
        game.location = location
        
        if !game.isGameActive && !game.isCompleted {
            if isScheduledGame {
                game.date = scheduledDate
            } else {
                game.date = Date()
            }
            game.quarters = quarters
            game.quarterDuration = (quarterMinutes * 60) + quarterSeconds
        }
        
        dismiss()
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}

// MARK: - Team Selection Row
struct TeamSelectionRow: View {
    let team: Team
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.red : Color(.systemGray5))
                        .frame(width: 44, height: 44)
                    
                    Text(String(team.name.prefix(2)).uppercased())
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(isSelected ? .white : .primary)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(team.name)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("\(team.players.count) players")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.red)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.red.opacity(0.1) : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.red : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Filter Chip Style
enum FilterChipStyle {
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

// MARK: - Filter Chip
struct FilterChip: View {
    let label: String
    let icon: String?
    let isActive: Bool
    let style: FilterChipStyle
    
    init(label: String, icon: String? = nil, isActive: Bool = false, style: FilterChipStyle = .secondary) {
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

#Preview {
    GameListView()
        .modelContainer(for: [Game.self, Team.self, Player.self], inMemory: true)
}
