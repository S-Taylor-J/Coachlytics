//
//  HomeView.swift
//  CoachingManager
//
//  Created by Taylor Santos on 06/01/2026.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("defaultTeamId") private var defaultTeamId: String = ""
    @Query(sort: \Game.date, order: .reverse) private var allGames: [Game]
    @Query(sort: \Team.name) private var teams: [Team]
    @Query(sort: \Player.number) private var allPlayers: [Player]
    
    @State private var selectedDate = Date()
    @State private var showPlayerStats = false
    @State private var selectedPlayer: Player?
    @State private var showAddNoteSheet = false
    @State private var showTeamStats = false
    @State private var calendarNotes: [Date: String] = [:]
    @State private var selectedScheduledGame: Game?
    
    private let calendar = Calendar.current
    
    // MARK: - Computed Properties
    private var myTeam: Team? {
        if defaultTeamId.isEmpty {
            return teams.first
        }
        return teams.first { $0.id.uuidString == defaultTeamId } ?? teams.first
    }
    
    private var games: [Game] {
        if let team = myTeam {
            return allGames.filter { $0.myTeamName == team.name }
        } else {
            return allGames
        }
    }
    
    private var teamPlayers: [Player] {
        myTeam?.players.sorted { $0.number < $1.number } ?? []
    }
    
    private var activeGames: [Game] {
        games.filter { $0.isGameActive && !$0.isCompleted }
    }
    
    private var completedGames: [Game] {
        games.filter { $0.isCompleted }
    }
    
    private var recentGames: [Game] {
        Array(completedGames.prefix(5))
    }
    
    private var scheduledGamesOnSelectedDate: [Game] {
        games.filter { game in
            game.isScheduled && calendar.isDate(game.date, inSameDayAs: selectedDate)
        }
    }
    
    private var seasonStats: SeasonStats {
        calculateSeasonStats()
    }
    
    private var upcomingEvents: [CalendarEvent] {
        getUpcomingEvents()
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // MARK: - Welcome Header
                        welcomeHeader
                        
                        // MARK: - Quick Stats Overview
                        quickStatsSection
                        
                        // MARK: - Active Game Alert
                        if !activeGames.isEmpty {
                            activeGameAlert
                        }
                        
                        // MARK: - Calendar Section
                        calendarSection
                        
                        // MARK: - Upcoming Events
                        upcomingEventsSection
                        
                        // MARK: - Player Stats Section
                        playerStatsSection
                        
                        // MARK: - Recent Results
                        recentResultsSection
                        
                        // MARK: - Season Performance
                        seasonPerformanceSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .padding(.bottom, 70)
                }
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showAddNoteSheet) {
                AddCalendarNoteSheet(
                    date: selectedDate,
                    existingNote: calendarNotes[calendar.startOfDay(for: selectedDate)] ?? ""
                ) { note in
                    if note.isEmpty {
                        calendarNotes.removeValue(forKey: calendar.startOfDay(for: selectedDate))
                    } else {
                        calendarNotes[calendar.startOfDay(for: selectedDate)] = note
                    }
                    saveCalendarNotes()
                }
            }
            .sheet(item: $selectedPlayer) { player in
                PlayerStatsSheet(player: player, games: games, teamPlayers: teamPlayers)
            }
            .sheet(isPresented: $showTeamStats) {
                TeamStatsSheet(games: completedGames, teamPlayers: teamPlayers, teamName: myTeam?.name ?? "Team")
            }
            .sheet(item: $selectedScheduledGame) { game in
                ScheduledGameDetailSheet(game: game, teams: Array(teams))
            }
            .onAppear {
                loadCalendarNotes()
            }
        }
    }
    
    // MARK: - Background
    private var backgroundGradient: some View {
        LinearGradient(
            colors: colorScheme == .dark
                ? [Color(.systemBackground), Color(.systemGray6)]
                : [Color(.systemGray6).opacity(0.5), Color(.systemBackground)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    // MARK: - Welcome Header
    private var welcomeHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text(greetingText)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                if let team = myTeam {
                    Text(team.name)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                } else {
                    Text("My Team")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                }
                
                Text("\(teamPlayers.count) players")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            // Team badge
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                
                Image(systemName: "sportscourt.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 8, x: 0, y: 4)
        )
    }
    
    private var greetingText: String {
        let hour = calendar.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        default: return "Good Evening"
        }
    }
    
    // MARK: - Quick Stats Section
    private var quickStatsSection: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            QuickStatCard(
                title: "Season Record",
                value: "\(seasonStats.wins)-\(seasonStats.draws)-\(seasonStats.losses)",
                subtitle: "\(seasonStats.winRate)% win rate",
                icon: "trophy.fill",
                gradientColors: [.yellow, .orange]
            )
            
            QuickStatCard(
                title: "Games Played",
                value: "\(completedGames.count)",
                subtitle: "\(activeGames.count) active",
                icon: "sportscourt.fill",
                gradientColors: [.green, .mint]
            )
            
            QuickStatCard(
                title: "Goals Scored",
                value: "\(seasonStats.goalsFor)",
                subtitle: "\(seasonStats.goalsAgainst) conceded",
                icon: "soccerball",
                gradientColors: [.blue, .cyan]
            )
            
            QuickStatCard(
                title: "Squad Size",
                value: "\(teamPlayers.count)",
                subtitle: "players",
                icon: "person.3.fill",
                gradientColors: [.purple, .pink]
            )
        }
    }
    
    // MARK: - Active Game Alert
    private var activeGameAlert: some View {
        VStack(spacing: 12) {
            ForEach(activeGames) { game in
                NavigationLink {
                    GameDetailView(game: game)
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.green.opacity(0.15))
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.green)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 8, height: 8)
                                Text("LIVE GAME")
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .foregroundColor(.green)
                            }
                            
                            Text("\(game.myTeamName) vs \(game.opponentName)")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundColor(.primary)
                            
                            Text("Q\(game.currentQuarter) • \(game.myTeamScore) - \(game.opponentScore)")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
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
            }
        }
    }
    
    // MARK: - Calendar Section
    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.red, .orange],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 28, height: 28)
                        
                        Image(systemName: "calendar")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    Text("Schedule")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                }
                
                Spacer()
                
                Button {
                    showAddNoteSheet = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .bold))
                        Text("Add Note")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.blue.opacity(0.1))
                    )
                }
            }
            
            // Calendar Grid
            CalendarGridView(
                selectedDate: $selectedDate,
                games: games,
                notes: calendarNotes
            )
            
            // Selected date info
            if let note = calendarNotes[calendar.startOfDay(for: selectedDate)], !note.isEmpty {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "note.text")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.orange)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(formattedSelectedDate)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        Text(note)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    Button {
                        showAddNoteSheet = true
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.orange.opacity(0.1))
                )
            }
            
            // Scheduled games on selected date
            ForEach(scheduledGamesOnSelectedDate) { game in
                Button {
                    selectedScheduledGame = game
                } label: {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "sportscourt.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.green)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(formattedSelectedDate)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                            Text("\(game.myTeamName) vs \(game.opponentName)")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.primary)
                            if !game.location.isEmpty {
                                HStack(spacing: 4) {
                                    Image(systemName: "location.fill")
                                        .font(.system(size: 10))
                                    Text(game.location)
                                        .font(.system(size: 11, weight: .medium))
                                }
                                .foregroundColor(.secondary)
                            }
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.system(size: 10))
                                Text(game.date.formatted(date: .omitted, time: .shortened))
                                    .font(.system(size: 11, weight: .medium))
                            }
                            .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.green.opacity(0.1))
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 8, x: 0, y: 4)
        )
    }
    
    private var formattedSelectedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: selectedDate)
    }
    
    // MARK: - Upcoming Events
    private var upcomingEventsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.purple, .indigo],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 28, height: 28)
                        
                        Image(systemName: "clock.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    Text("Upcoming")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                }
                
                Spacer()
            }
            
            if upcomingEvents.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "calendar.badge.checkmark")
                            .font(.system(size: 28))
                            .foregroundColor(.secondary.opacity(0.5))
                        Text("No upcoming events")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 20)
                    Spacer()
                }
            } else {
                ForEach(upcomingEvents.prefix(3)) { event in
                    UpcomingEventRow(event: event)
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
    
    // MARK: - Player Stats Section
    private var playerStatsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.cyan, .blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 28, height: 28)
                        
                        Image(systemName: "person.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Player Stats")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                        Text("Tap a player for details")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button {
                    showTeamStats = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chart.bar.doc.horizontal")
                            .font(.system(size: 11, weight: .bold))
                        Text("Team Stats")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.blue.opacity(0.1))
                    )
                }
            }
            
            if teamPlayers.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 28))
                            .foregroundColor(.secondary.opacity(0.5))
                        Text("No players in team")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 20)
                    Spacer()
                }
            } else {
                // Top performers quick view
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(teamPlayers.prefix(8)) { player in
                            PlayerQuickCard(
                                player: player,
                                stats: getPlayerStats(player)
                            ) {
                                selectedPlayer = player
                            }
                        }
                    }
                    .padding(.horizontal, 2)
                    .padding(.vertical, 4)
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
    
    // MARK: - Recent Results Section
    private var recentResultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.orange, .red],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 28, height: 28)
                        
                        Image(systemName: "flag.checkered")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    Text("Recent Results")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                }
                
                Spacer()
                
                if completedGames.count > 5 {
                    NavigationLink {
                        GameListView()
                    } label: {
                        Text("See All")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(.blue)
                    }
                }
            }
            
            if recentGames.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "sportscourt")
                            .font(.system(size: 28))
                            .foregroundColor(.secondary.opacity(0.5))
                        Text("No completed games yet")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 20)
                    Spacer()
                }
            } else {
                VStack(spacing: 8) {
                    ForEach(recentGames) { game in
                        RecentGameRow(game: game)
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
    
    // MARK: - Season Performance Section
    private var seasonPerformanceSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.green, .mint],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 28, height: 28)
                        
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    Text("Season Performance")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                }
                
                Spacer()
            }
            
            // Form streak
            if !completedGames.isEmpty {
                VStack(spacing: 12) {
                    // Current form
                    HStack(spacing: 6) {
                        Text("Form:")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        ForEach(Array(recentGames.prefix(5).enumerated()), id: \.offset) { _, game in
                            FormBadge(result: game.resultString)
                        }
                        
                        Spacer()
                    }
                    
                    Divider()
                    
                    // Stats breakdown
                    HStack(spacing: 0) {
                        PerformanceStatItem(
                            label: "Avg Goals",
                            value: String(format: "%.1f", seasonStats.avgGoalsFor),
                            color: .blue
                        )
                        
                        Divider()
                            .frame(height: 40)
                        
                        PerformanceStatItem(
                            label: "Avg Conceded",
                            value: String(format: "%.1f", seasonStats.avgGoalsAgainst),
                            color: .red
                        )
                        
                        Divider()
                            .frame(height: 40)
                        
                        PerformanceStatItem(
                            label: "Goal Diff",
                            value: seasonStats.goalDifference >= 0 ? "+\(seasonStats.goalDifference)" : "\(seasonStats.goalDifference)",
                            color: seasonStats.goalDifference >= 0 ? .green : .red
                        )
                    }
                }
            } else {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "chart.bar")
                            .font(.system(size: 28))
                            .foregroundColor(.secondary.opacity(0.5))
                        Text("Complete games to see stats")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 20)
                    Spacer()
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
    
    // MARK: - Helper Functions
    private func calculateSeasonStats() -> SeasonStats {
        let completed = completedGames
        let wins = completed.filter { $0.myTeamScore > $0.opponentScore }.count
        let draws = completed.filter { $0.myTeamScore == $0.opponentScore }.count
        let losses = completed.filter { $0.myTeamScore < $0.opponentScore }.count
        let goalsFor = completed.reduce(0) { $0 + $1.myTeamScore }
        let goalsAgainst = completed.reduce(0) { $0 + $1.opponentScore }
        let total = completed.count
        
        return SeasonStats(
            wins: wins,
            draws: draws,
            losses: losses,
            goalsFor: goalsFor,
            goalsAgainst: goalsAgainst,
            gamesPlayed: total
        )
    }
    
    private func getUpcomingEvents() -> [CalendarEvent] {
        var events: [CalendarEvent] = []
        let now = Date()
        let upcoming = calendar.date(byAdding: .day, value: 14, to: now)!
        
        // Add scheduled games as events
        let scheduledGames = games.filter { $0.isScheduled && $0.date >= now && $0.date <= upcoming }
        for game in scheduledGames {
            events.append(CalendarEvent(
                id: game.id,
                date: game.date,
                title: "\(game.myTeamName) vs \(game.opponentName)",
                type: .game
            ))
        }
        
        // Add notes as events
        for (date, note) in calendarNotes {
            if date >= calendar.startOfDay(for: now) && date <= upcoming {
                events.append(CalendarEvent(
                    id: UUID(),
                    date: date,
                    title: note,
                    type: .note
                ))
            }
        }
        
        return events.sorted { $0.date < $1.date }
    }
    
    private func getPlayerStats(_ player: Player) -> PlayerGameStats {
        var totalEvents = 0
        var infractions = 0
        var circleEntries = 0
        var goals = 0
        var turnovers = 0
//        var totalPlayTime: TimeInterval = 0
        
        for game in completedGames {
            let playerEvents = game.events.filter { $0.playerId == player.id && $0.team == .ourTeam }
            totalEvents += playerEvents.count
            infractions += playerEvents.filter { $0.eventType == .infraction }.count
            circleEntries += playerEvents.filter { $0.eventType == .circleEntry }.count
            goals += playerEvents.filter { $0.eventType == .goal || ($0.eventType == .circleEntry && $0.circleResult == .goal) }.count
            turnovers += playerEvents.filter { $0.eventType == .turnover }.count
//            totalPlayTime += game.totalPlayTime(forPlayer: player.id)
        }
        
        return PlayerGameStats(
            totalEvents: totalEvents,
            infractions: infractions,
            circleEntries: circleEntries,
            goals: goals,
            turnovers: turnovers,
            gamesPlayed: completedGames.count
//            totalPlayTime: totalPlayTime
        )
    }
    
    // MARK: - Persistence
    private func loadCalendarNotes() {
        if let data = UserDefaults.standard.data(forKey: "calendarNotes"),
           let notes = try? JSONDecoder().decode([String: String].self, from: data) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            calendarNotes = notes.reduce(into: [:]) { result, pair in
                if let date = dateFormatter.date(from: pair.key) {
                    result[calendar.startOfDay(for: date)] = pair.value
                }
            }
        }
    }
    
    private func saveCalendarNotes() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        var stringKeyed: [String: String] = [:]
        for (date, note) in calendarNotes {
            let key = dateFormatter.string(from: calendar.startOfDay(for: date))
            stringKeyed[key] = note
        }
        if let data = try? JSONEncoder().encode(stringKeyed) {
            UserDefaults.standard.set(data, forKey: "calendarNotes")
        }
    }
}

// MARK: - Scheduled Game Detail Sheet
struct ScheduledGameDetailSheet: View {
    var game: Game
    let teams: [Team]
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var showEditSheet = false
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
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
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Match Header
                    VStack(spacing: 16) {
                        HStack(spacing: 20) {
                            // My Team
                            VStack(spacing: 8) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [.red, .red.opacity(0.7)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 64, height: 64)
                                    Text(String(game.myTeamName.prefix(2)).uppercased())
                                        .font(.system(size: 20, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                }
                                Text(game.myTeamName)
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity)
                            
                            VStack(spacing: 4) {
                                Text("VS")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.secondary)
                                
                                Text(daysUntil)
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundColor(.orange)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .fill(Color.orange.opacity(0.15))
                                    )
                            }
                            
                            // Opponent
                            VStack(spacing: 8) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [.blue, .blue.opacity(0.7)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 64, height: 64)
                                    Text(String(game.opponentName.prefix(2)).uppercased())
                                        .font(.system(size: 20, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                }
                                Text(game.opponentName)
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 8, x: 0, y: 4)
                    )
                    
                    // Game Details
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.blue)
                            Text("Game Details")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                        }
                        
                        VStack(spacing: 12) {
                            // Date
                            HStack {
                                Image(systemName: "calendar")
                                    .font(.system(size: 14))
                                    .foregroundColor(.orange)
                                    .frame(width: 24)
                                Text("Date")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(formattedDate)
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            
                            Divider()
                            
                            // Time
                            HStack {
                                Image(systemName: "clock")
                                    .font(.system(size: 14))
                                    .foregroundColor(.orange)
                                    .frame(width: 24)
                                Text("Time")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(formattedTime)
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            
                            if !game.location.isEmpty {
                                Divider()
                                
                                // Location
                                HStack {
                                    Image(systemName: "location.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.green)
                                        .frame(width: 24)
                                    Text("Location")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(game.location)
                                        .font(.system(size: 14, weight: .semibold))
                                        .multilineTextAlignment(.trailing)
                                }
                            }
                            
                            Divider()
                            
                            // Quarters
                            HStack {
                                Image(systemName: "clock.badge.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.purple)
                                    .frame(width: 24)
                                Text("Format")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                                Spacer()
                                let mins = game.quarterDurationInSeconds / 60
                                let secs = game.quarterDurationInSeconds % 60
                                Text("\(game.quarters) quarters × \(mins):\(String(format: "%02d", secs))")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 8, x: 0, y: 4)
                    )
                    
                    // Actions
                    VStack(spacing: 12) {
                        Button {
                            showEditSheet = true
                        } label: {
                            HStack {
                                Image(systemName: "pencil")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Edit Game Details")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                            }
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.blue.opacity(0.1))
                            )
                        }
                        
                        NavigationLink {
                            GameDetailView(game: game)
                        } label: {
                            HStack {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Start Game")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        LinearGradient(
                                            colors: [.green, .green.opacity(0.8)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                        }
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
            .navigationTitle("Scheduled Game")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showEditSheet) {
                EditGameSheet(game: game, teams: teams)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [Game.self, Team.self, Player.self], inMemory: true)
}

