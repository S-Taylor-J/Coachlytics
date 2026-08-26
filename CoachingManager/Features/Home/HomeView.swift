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
    @State private var showAddPlayerSheet = false
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

    private var nextScheduledGame: Game? {
        games
            .filter { $0.isScheduled && $0.date >= Date() }
            .sorted { $0.date < $1.date }
            .first
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
                    VStack(spacing: 24) {
                        dashboardTopBar

                        teamHeroSummaryCard

                        if !activeGames.isEmpty {
                            activeGameAlert
                        }

                        premiumSeasonSnapshot

                        premiumScheduleSection

                        premiumCalendarSection

                        recentActivitySection

                        quickActionsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, 96)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
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
            .sheet(isPresented: $showAddPlayerSheet) {
                AddPlayerSheet(selectedTeam: myTeam)
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
                    brandAccent.opacity(colorScheme == .dark ? 0.14 : 0.16),
                    Color.clear,
                    Color(red: 0.13, green: 0.83, blue: 0.58).opacity(colorScheme == .dark ? 0.05 : 0.10)
                ],
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
        }
    }

    // MARK: - Premium Dashboard
    private var dashboardTopBar: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("\(greetingText), Coach")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(textSecondary)

                Text("Dashboard")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundStyle(primaryText)

                // Text("Coachlytics team command center")
                //     .font(.system(size: 14, weight: .medium, design: .rounded))
                //     .foregroundStyle(textMuted)
            }

            Spacer()

            ZStack {
                Circle()
                    .fill(heroGlassFill)
                    .frame(width: 62, height: 62)
                    .overlay(
                        Circle()
                            .stroke(brandAccent.opacity(0.34), lineWidth: 1)
                    )
                    .shadow(color: brandAccent.opacity(0.18), radius: 18, x: 0, y: 10)

                Image(systemName: "sportscourt.fill")
                    .font(.system(size: 25, weight: .semibold))
                    .foregroundStyle(brandAccent)
            }
        }
    }

    private var teamHeroSummaryCard: some View {
        Button {
            showTeamStats = true
        } label: {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(heroCardGradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        brandAccent.opacity(0.7),
                                        Color.white.opacity(0.12),
                                        Color(red: 0.15, green: 0.95, blue: 0.66).opacity(0.22)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: brandAccent.opacity(0.28), radius: 28, x: 0, y: 16)

                TacticalFieldGraphic()
                    .stroke(brandAccent.opacity(0.22), lineWidth: 1)
                    .frame(width: 210, height: 164)
                    .rotationEffect(.degrees(8))
                    .offset(x: 40, y: 22)
                    .allowsHitTesting(false)

                VStack(alignment: .leading, spacing: 22) {
                    HStack(alignment: .top, spacing: 14) {
                        teamAvatar(size: 58)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Your Team")
                                .font(.system(size: 12, weight: .heavy, design: .rounded))
                                .tracking(1.2)
                                .foregroundStyle(brandAccent)

                            Text(myTeam?.name ?? "Team")
                                .font(.system(size: 33, weight: .black, design: .rounded))
                                .foregroundStyle(heroPrimaryText)
                                .lineLimit(1)
                                .minimumScaleFactor(0.72)

                            HStack(spacing: 8) {
                                miniPill(icon: "person.3.fill", text: "\(teamPlayers.count)")
                                miniPill(icon: "chart.line.uptrend.xyaxis", text: "\(seasonStats.winRate)% win")
                            }
                        }

                        Spacer(minLength: 0)

                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(heroPrimaryText)
                            .frame(width: 42, height: 42)
                            .background(
                                Circle()
                                    .fill(heroControlFill)
                                    .overlay(Circle().stroke(heroStroke, lineWidth: 1))
                            )
                    }

                    HStack(alignment: .bottom, spacing: 18) {
                        heroMetric(label: "Record", value: "\(seasonStats.wins)-\(seasonStats.draws)-\(seasonStats.losses)")
                        heroDivider
                        heroMetric(label: "Win %", value: "\(seasonStats.winRate)%", accent: brandAccent)
                        heroDivider
                        heroMetric(label: "Players", value: "\(teamPlayers.count)")
                    }

                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Recent form")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(textSecondary)

                            Text(formSummaryText)
                                .font(.system(size: 13, weight: .black, design: .rounded))
                                .foregroundStyle(formTrendColor)
                        }

                        Spacer()

                        HStack(spacing: 7) {
                            ForEach(Array(recentFormBadges.enumerated()), id: \.offset) { _, badge in
                                Text(badge)
                                    .font(.system(size: 11, weight: .black, design: .rounded))
                                    .foregroundStyle(.white)
                                    .frame(width: 28, height: 28)
                                    .background(
                                        Circle()
                                            .fill(formBadgeColor(badge))
                                            .shadow(color: formBadgeColor(badge).opacity(0.28), radius: 8, x: 0, y: 4)
                                    )
                            }
                        }
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(heroInsetFill)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(heroStroke, lineWidth: 1)
                            )
                    )
                }
                .padding(20)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open team analytics for \(myTeam?.name ?? "team")")
    }

    private var premiumSeasonSnapshot: some View {
        VStack(alignment: .leading, spacing: 14) {
            dashboardSectionHeader(
                title: "Season Snapshot",
                subtitle: "Live performance overview",
                ctaTitle: "Team Stats",
                ctaIcon: "chart.bar.xaxis"
            ) {
                showTeamStats = true
            }

            LazyVGrid(columns: dashboardGridColumns, spacing: 12) {
                ForEach(snapshotMetrics) { metric in
                    PremiumMetricCard(metric: metric)
                }
            }
        }
    }

    private var premiumScheduleSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            dashboardSectionHeader(
                title: "Upcoming Schedule",
                subtitle: "Next training and match",
                // ctaTitle: "Calendar",
                // ctaIcon: "calendar"
             ) //{
            //     showAddNoteSheet = true
            // }

            VStack(spacing: 10) {
                ScheduleTimelineCard(
                    title: "Team Training",
                    eyebrow: "Next training",
                    dateText: premiumDateText(for: nextTrainingDate),
                    detail: trainingDetailText,
                    venue: trainingVenueText,
                    icon: "figure.run",
                    tint: brandAccent,
                    priority: "Medium"
                )

                if let game = nextScheduledGame {
                    Button {
                        selectedScheduledGame = game
                    } label: {
                        ScheduleTimelineCard(
                            title: game.opponentName,
                            eyebrow: "Next match",
                            dateText: premiumDateText(for: game.date),
                            detail: "\(game.myTeamName) vs \(game.opponentName)",
                            venue: game.location.isEmpty ? "Venue TBC" : game.location,
                            icon: "sportscourt.fill",
                            tint: Color(red: 0.16, green: 0.92, blue: 0.59),
                            priority: matchPriorityText(for: game)
                        )
                    }
                    .buttonStyle(.plain)
                } else {
                    ScheduleTimelineCard(
                        title: "No match scheduled",
                        eyebrow: "Next match",
                        dateText: "Add fixture",
                        detail: "Create your next opponent and venue",
                        venue: "Schedule board",
                        icon: "plus.circle.fill",
                        tint: Color(red: 1.0, green: 0.62, blue: 0.22),
                        priority: "Open"
                    )
                }
            }

            NavigationLink {
                GameListView(selectedTab: .constant(.game))
            } label: {
                HStack(spacing: 8) {
                    Text("View full Schedule")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundStyle(primaryText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(themeSurfaceFill)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(themeStroke, lineWidth: 1)
                        )
                )
            }
        }
    }

    private var premiumCalendarSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            dashboardSectionHeader(
                title: "Calendar",
                subtitle: "Plan training, matchdays, and reminders",
                ctaTitle: "Add Note",
                ctaIcon: "plus"
            ) {
                showAddNoteSheet = true
            }

            VStack(spacing: 14) {
                CalendarGridView(
                    selectedDate: $selectedDate,
                    games: games,
                    notes: calendarNotes
                )
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(themeSurfaceFill)
                        .background(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(.ultraThinMaterial)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(themeStroke, lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.22 : 0.10), radius: 16, x: 0, y: 10)
                )

                selectedDatePanel
            }
        }
    }

    @ViewBuilder
    private var selectedDatePanel: some View {
        let note = calendarNotes[calendar.startOfDay(for: selectedDate)]
        let gamesForDate = scheduledGamesOnSelectedDate

        if note != nil || !gamesForDate.isEmpty {
            VStack(spacing: 8) {
                if let note = note, !note.isEmpty {
                    Button {
                        showAddNoteSheet = true
                    } label: {
                        CalendarInfoRow(
                            title: formattedSelectedDate,
                            detail: note,
                            icon: "note.text",
                            tint: Color(red: 1.0, green: 0.62, blue: 0.22)
                        )
                    }
                    .buttonStyle(.plain)
                }

                ForEach(gamesForDate) { game in
                    Button {
                        selectedScheduledGame = game
                    } label: {
                        CalendarInfoRow(
                            title: "\(game.myTeamName) vs \(game.opponentName)",
                            detail: game.location.isEmpty ? game.date.formatted(date: .omitted, time: .shortened) : "\(game.location) • \(game.date.formatted(date: .omitted, time: .shortened))",
                            icon: "sportscourt.fill",
                            tint: Color(red: 0.16, green: 0.92, blue: 0.59)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        } else {
            Button {
                showAddNoteSheet = true
            } label: {
                CalendarInfoRow(
                    title: formattedSelectedDate,
                    detail: "No events yet. Add a note or schedule a fixture.",
                    icon: "calendar.badge.plus",
                    tint: brandAccent
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            dashboardSectionHeader(title: "Recent Activity", subtitle: "Latest team updates")

            VStack(spacing: 8) {
                ForEach(recentActivityItems) { item in
                    ActivityFeedRow(item: item)
                }
            }
        }
    }

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            dashboardSectionHeader(title: "Quick Actions", subtitle: "Coach workflows")

            LazyVGrid(columns: dashboardGridColumns, spacing: 12) {
                NavigationLink {
                    GameListView(selectedTab: .constant(.game))
                } label: {
                    QuickActionTile(title: "Add Match", icon: "plus.circle.fill", tint: brandAccent)
                }
                .buttonStyle(.plain)

                Button {
                    selectedDate = nextTrainingDate
                    showAddNoteSheet = true
                } label: {
                    QuickActionTile(title: "Log Training", icon: "figure.run.circle.fill", tint: Color(red: 0.16, green: 0.92, blue: 0.59))
                }
                .buttonStyle(.plain)

                Button {
                    showAddPlayerSheet = true
                } label: {
                    QuickActionTile(title: "Add Player", icon: "person.crop.circle.badge.plus", tint: Color(red: 0.67, green: 0.48, blue: 1.0))
                }
                .buttonStyle(.plain)

                NavigationLink {
                    GameListView(selectedTab: .constant(.game))
                } label: {
                    QuickActionTile(title: "Record Stats", icon: "chart.line.uptrend.xyaxis.circle.fill", tint: Color(red: 1.0, green: 0.62, blue: 0.22))
                }
                .buttonStyle(.plain)

                Button {
                    showTeamStats = true
                } label: {
                    QuickActionTile(title: "View Analytics", icon: "chart.bar.doc.horizontal.fill", tint: Color(red: 0.22, green: 0.82, blue: 1.0))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var dashboardGridColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]
    }

    private var snapshotMetrics: [DashboardMetric] {
        [
            DashboardMetric(
                title: "Season Record",
                value: "\(seasonStats.wins)-\(seasonStats.draws)-\(seasonStats.losses)",
                subtitle: "\(seasonStats.winRate)% win rate",
                icon: "trophy.fill",
                tint: Color(red: 1.0, green: 0.72, blue: 0.20)
            ),
            DashboardMetric(
                title: "Games Played",
                value: "\(completedGames.count)",
                subtitle: "\(activeGames.count) live now",
                icon: "calendar.badge.clock",
                tint: Color(red: 0.18, green: 0.91, blue: 0.62)
            ),
            DashboardMetric(
                title: "Goals Scored",
                value: "\(seasonStats.goalsFor)",
                subtitle: "\(seasonStats.goalsAgainst) conceded",
                icon: "scope",
                tint: brandAccent
            ),
            DashboardMetric(
                title: "Squad Size",
                value: "\(teamPlayers.count)",
                subtitle: "players registered",
                icon: "person.3.fill",
                tint: Color(red: 0.66, green: 0.49, blue: 1.0)
            ),
            DashboardMetric(
                title: "Active Players",
                value: "\(teamPlayers.count)",
                subtitle: "\(max(teamPlayers.count - activeGames.count, 0)) available",
                icon: "bolt.heart.fill",
                tint: Color(red: 0.18, green: 0.82, blue: 1.0)
            ),
            DashboardMetric(
                title: "Upcoming",
                value: "\(upcomingMatchCount)",
                subtitle: "matches in 14 days",
                icon: "flag.checkered",
                tint: Color(red: 1.0, green: 0.55, blue: 0.22)
            )
        ]
    }

    private var upcomingMatchCount: Int {
        let now = Date()
        let endDate = calendar.date(byAdding: .day, value: 14, to: now) ?? now
        return games.filter { $0.isScheduled && $0.date >= now && $0.date <= endDate }.count
    }

    private var recentActivityItems: [DashboardActivityItem] {
        var items: [DashboardActivityItem] = []

        if let activeGame = activeGames.first {
            items.append(
                DashboardActivityItem(
                    title: "Live match in progress",
                    detail: "\(activeGame.myTeamName) vs \(activeGame.opponentName)",
                    timestamp: "Now",
                    icon: "play.circle.fill",
                    tint: Color(red: 0.16, green: 0.92, blue: 0.59)
                )
            )
        }

        for game in recentGames.prefix(2) {
            items.append(
                DashboardActivityItem(
                    title: "Match recorded",
                    detail: "\(game.myTeamName) \(game.myTeamScore)-\(game.opponentScore) \(game.opponentName)",
                    timestamp: relativeActivityTime(for: game.date),
                    icon: "checkmark.seal.fill",
                    tint: game.myTeamScore >= game.opponentScore ? Color(red: 0.16, green: 0.92, blue: 0.59) : Color(red: 1.0, green: 0.48, blue: 0.36)
                )
            )
        }

        if let player = teamPlayers.sorted(by: { $0.number > $1.number }).first {
            items.append(
                DashboardActivityItem(
                    title: "Player added",
                    detail: "#\(player.number) \(player.name)",
                    timestamp: "Roster",
                    icon: "person.fill.checkmark",
                    tint: Color(red: 0.67, green: 0.48, blue: 1.0)
                )
            )
        }

        if let note = calendarNotes.sorted(by: { $0.key > $1.key }).first {
            items.append(
                DashboardActivityItem(
                    title: note.value.localizedCaseInsensitiveContains("training") ? "Training completed" : "Schedule updated",
                    detail: note.value,
                    timestamp: relativeActivityTime(for: note.key),
                    icon: "clipboard.fill",
                    tint: Color(red: 1.0, green: 0.62, blue: 0.22)
                )
            )
        }

        if items.isEmpty {
            items.append(contentsOf: [
                DashboardActivityItem(
                    title: "Coachlytics workspace ready",
                    detail: "Add a match to start tracking performance",
                    timestamp: "Today",
                    icon: "sparkles",
                    tint: brandAccent
                ),
                DashboardActivityItem(
                    title: "Squad setup pending",
                    detail: "Create players and positions for richer analytics",
                    timestamp: "Next",
                    icon: "person.3.fill",
                    tint: Color(red: 0.67, green: 0.48, blue: 1.0)
                )
            ])
        }

        return Array(items.prefix(4))
    }

    private var recentFormBadges: [String] {
        let badges = recentGames.prefix(5).map { game -> String in
            if game.myTeamScore > game.opponentScore { return "W" }
            if game.myTeamScore == game.opponentScore { return "D" }
            return "L"
        }
        return badges.isEmpty ? ["-", "-", "-", "-", "-"] : badges
    }

    private var formTrendColor: Color {
        guard seasonStats.gamesPlayed > 0 else { return textSecondary }
        return seasonStats.winRate >= 60 ? Color(red: 0.16, green: 0.92, blue: 0.59) : Color(red: 1.0, green: 0.62, blue: 0.22)
    }

    private var formSummaryText: String {
        guard seasonStats.gamesPlayed > 0 else { return "Baseline" }
        if seasonStats.winRate >= 70 { return "Elite form" }
        if seasonStats.winRate >= 50 { return "Positive" }
        return "Needs focus"
    }

    private var nextTrainingDate: Date {
        let now = Date()
        if let noteDate = calendarNotes
            .filter({ $0.key >= calendar.startOfDay(for: now) && $0.value.localizedCaseInsensitiveContains("training") })
            .map(\.key)
            .sorted()
            .first {
            return noteDate
        }

        let targetWeekday = 4
        let targetHour = 18
        let targetMinute = 30
        for offset in 0..<10 {
            guard let candidateDay = calendar.date(byAdding: .day, value: offset, to: now) else { continue }
            let weekday = calendar.component(.weekday, from: candidateDay)
            if weekday == targetWeekday,
               let training = calendar.date(bySettingHour: targetHour, minute: targetMinute, second: 0, of: candidateDay),
               training > now {
                return training
            }
        }

        return calendar.date(byAdding: .day, value: 2, to: now) ?? now
    }

    private var trainingDetailText: String {
        if let note = calendarNotes.first(where: { calendar.isDate($0.key, inSameDayAs: nextTrainingDate) })?.value {
            return note
        }
        return "Conditioning, tactical shape, set pieces"
    }

    private var trainingVenueText: String {
        "Training ground"
    }

    private var textSecondary: Color {
        colorScheme == .dark ? Color.white.opacity(0.72) : Color(red: 0.25, green: 0.31, blue: 0.41)
    }

    private var textMuted: Color {
        colorScheme == .dark ? Color.white.opacity(0.46) : Color(red: 0.45, green: 0.50, blue: 0.60)
    }

    private var primaryText: Color {
        colorScheme == .dark ? .white : Color(red: 0.035, green: 0.055, blue: 0.090)
    }

    private var themeSurfaceFill: Color {
        colorScheme == .dark ? Color.white.opacity(0.065) : Color.white.opacity(0.86)
    }

    private var themeSecondarySurfaceFill: Color {
        colorScheme == .dark ? Color.white.opacity(0.055) : Color.white.opacity(0.72)
    }

    private var themeStroke: Color {
        colorScheme == .dark ? Color.white.opacity(0.10) : Color(red: 0.55, green: 0.64, blue: 0.78).opacity(0.24)
    }

    private var heroPrimaryText: Color {
        colorScheme == .dark ? .white : Color(red: 0.030, green: 0.055, blue: 0.105)
    }

    private var heroSecondaryText: Color {
        colorScheme == .dark ? Color.white.opacity(0.86) : Color(red: 0.25, green: 0.31, blue: 0.42)
    }

    private var heroControlFill: Color {
        colorScheme == .dark ? Color.white.opacity(0.12) : Color.white.opacity(0.78)
    }

    private var heroInsetFill: Color {
        colorScheme == .dark ? Color.black.opacity(0.18) : Color.white.opacity(0.70)
    }

    private var heroStroke: Color {
        colorScheme == .dark ? Color.white.opacity(0.10) : Color.white.opacity(0.62)
    }

    private var heroGlassFill: LinearGradient {
        LinearGradient(
            colors: colorScheme == .dark ? [Color.white.opacity(0.12), Color.white.opacity(0.04)] : [Color.white.opacity(0.95), Color.white.opacity(0.62)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var heroCardGradient: LinearGradient {
        LinearGradient(
            colors: colorScheme == .dark ? [
                Color(red: 0.055, green: 0.085, blue: 0.145),
                Color(red: 0.035, green: 0.080, blue: 0.170),
                Color(red: 0.015, green: 0.160, blue: 0.360)
            ] : [
                Color(red: 0.925, green: 0.960, blue: 1.000),
                Color(red: 0.830, green: 0.900, blue: 1.000),
                Color(red: 0.700, green: 0.840, blue: 1.000)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func dashboardSectionHeader(
        title: String,
        subtitle: String,
        ctaTitle: String? = nil,
        ctaIcon: String? = nil,
        action: (() -> Void)? = nil
    ) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(primaryText)

                Text(subtitle)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(textMuted)
            }

            Spacer()

            if let ctaTitle = ctaTitle, let action = action {
                Button(action: action) {
                    HStack(spacing: 6) {
                        if let ctaIcon = ctaIcon {
                            Image(systemName: ctaIcon)
                                .font(.system(size: 12, weight: .bold))
                        }
                        Text(ctaTitle)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(brandAccent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(brandAccent.opacity(0.13))
                            .overlay(Capsule().stroke(brandAccent.opacity(0.22), lineWidth: 1))
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func teamAvatar(size: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [brandAccent, Color(red: 0.17, green: 0.35, blue: 1.0)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
                .shadow(color: brandAccent.opacity(0.35), radius: 16, x: 0, y: 10)

            Text(teamInitials)
                .font(.system(size: size * 0.32, weight: .black, design: .rounded))
                .foregroundStyle(.white)
        }
    }

    private var teamInitials: String {
        let words = (myTeam?.name ?? "Coachlytics").split(separator: " ")
        let initials = words.prefix(2).compactMap { $0.first }.map(String.init).joined()
        return initials.isEmpty ? "CL" : initials.uppercased()
    }

    private func miniPill(icon: String, text: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .bold))
            Text(text)
                .font(.system(size: 11, weight: .bold, design: .rounded))
        }
        .foregroundStyle(heroSecondaryText)
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(heroControlFill)
                .overlay(Capsule().stroke(heroStroke, lineWidth: 1))
        )
    }

    private func heroMetric(label: String, value: String, accent: Color? = nil) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(textMuted)
            Text(value)
                .font(.system(size: 25, weight: .black, design: .rounded))
                .foregroundStyle(accent ?? heroPrimaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var heroDivider: some View {
        Rectangle()
            .fill(heroStroke)
            .frame(width: 1, height: 44)
    }

    private func premiumDateText(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d • h:mm a"
        return formatter.string(from: date)
    }

    private func matchPriorityText(for game: Game) -> String {
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: Date()), to: calendar.startOfDay(for: game.date)).day ?? 0
        if days <= 1 { return "High" }
        if days <= 7 { return "Focus" }
        return "Normal"
    }

    private func relativeActivityTime(for date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func formBadgeColor(_ badge: String) -> Color {
        switch badge {
        case "W": return Color(red: 0.16, green: 0.92, blue: 0.59)
        case "D": return Color(red: 1.0, green: 0.62, blue: 0.22)
        case "L": return Color(red: 1.0, green: 0.36, blue: 0.32)
        default: return Color.white.opacity(0.14)
        }
    }

    // MARK: - Welcome Header
    private var welcomeHeader: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(greetingText)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .secondary)

                    Text(myTeam?.name ?? "My Team")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundColor(colorScheme == .dark ? .white : .primary)

                    Text("\(teamPlayers.count) players")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.85) : .secondary)
                }

                Spacer()

                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [brandAccent, brandAccentSoft],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)

                    Image(systemName: "sportscourt.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                        .shadow(color: brandAccent.opacity(0.6), radius: 6, x: 0, y: 2)
                }
            }

            HStack(spacing: 10) {
                statChip(label: "Record", value: "\(seasonStats.wins)-\(seasonStats.draws)-\(seasonStats.losses)")
                statChip(label: "Win Rate", value: "\(seasonStats.winRate)%")
            }

            if let nextGame = nextScheduledGame {
                HStack(spacing: 8) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Next: \(nextGame.opponentName)")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                    Text(nextGame.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .secondary)
                }
                .foregroundColor(colorScheme == .dark ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.06))
                )
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(colorScheme == .dark ? brandNavy : Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(brandAccent.opacity(colorScheme == .dark ? 0.5 : 0.35), lineWidth: 1)
                )
            .shadow(color: brandAccent.opacity(colorScheme == .dark ? 0.32 : 0.22), radius: 18, x: 0, y: 10)
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
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                sectionHeader(title: "Season Snapshot", subtitle: "Team overview")

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
                    .foregroundColor(brandAccent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(brandAccent.opacity(0.12))
                    )
                }
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                QuickStatCard(
                    title: "Season Record",
                    value: "\(seasonStats.wins)-\(seasonStats.draws)-\(seasonStats.losses)",
                    subtitle: "\(seasonStats.winRate)% win rate",
                    icon: "",
                    gradientColors: [.yellow, .yellow]
                )

                QuickStatCard(
                    title: "Games Played",
                    value: "\(completedGames.count)",
                    subtitle: "\(activeGames.count) active",
                    icon: "",
                    gradientColors: [.green, .green]
                )

                QuickStatCard(
                    title: "Goals Scored",
                    value: "\(seasonStats.goalsFor)",
                    subtitle: "\(seasonStats.goalsAgainst) conceded",
                    icon: "",
                    gradientColors: [.blue, .blue]
                )

                QuickStatCard(
                    title: "Squad Size",
                    value: "\(teamPlayers.count)",
                    subtitle: "players",
                    icon: "",
                    gradientColors: [.purple, .purple]
                )
            }
        }
        .padding(16)
        .background(cardSurface(accent: brandAccent))
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
                    .background(cardSurface(accent: .green))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.green.opacity(0.35), lineWidth: 1.5)
                    )
                }
            }
        }
    }

    // MARK: - Calendar Section
    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                sectionHeader(title: "Schedule", subtitle: "Training and matches")

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
                    .foregroundColor(brandAccent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(brandAccent.opacity(0.12))
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
        .background(cardSurface(accent: .orange))
    }

    private var formattedSelectedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: selectedDate)
    }

    // MARK: - Upcoming Events
    private var upcomingEventsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Upcoming", subtitle: "Next 14 days")

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
        .background(cardSurface(accent: .purple))
    }

    // MARK: - Player Stats Section
    private var playerStatsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                sectionHeader(title: "Player Stats", subtitle: "Tap a player for details")

                Spacer()

                // Button {
                //     showTeamStats = true
                // } label: {
                //     HStack(spacing: 4) {
                //         Image(systemName: "chart.bar.doc.horizontal")
                //             .font(.system(size: 11, weight: .bold))
                //         Text("Team Stats")
                //             .font(.system(size: 12, weight: .semibold, design: .rounded))
                //     }
                //     .foregroundColor(brandAccent)
                //     .padding(.horizontal, 12)
                //     .padding(.vertical, 6)
                //     .background(
                //         Capsule()
                //             .fill(brandAccent.opacity(0.12))
                //     )
                // }
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
        .background(cardSurface(accent: .cyan))
    }

    // MARK: - Recent Results Section
    private var recentResultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionHeader(title: "Recent Results", subtitle: "Last 5 games")

                Spacer()

                if completedGames.count > 5 {
                    NavigationLink {
                        GameListView(selectedTab: .constant(.home))
                    } label: {
                        Text("See All")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(brandAccent)
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
        .background(cardSurface(accent: .orange))
    }

    // MARK: - Season Performance Section
    private var seasonPerformanceSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "Season Performance", subtitle: "Form and averages")

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
        .background(cardSurface(accent: .green))
    }

    // MARK: - Styling Helpers
    private var brandAccent: Color {
        Color(red: 0.42, green: 0.70, blue: 1.0)
    }

    private var brandAccentSoft: Color {
        Color(red: 0.55, green: 0.80, blue: 1.0)
    }

    private var brandNavy: Color {
        Color(red: 0.08, green: 0.10, blue: 0.16)
    }

    private var brandMidnight: Color {
        Color(red: 0.05, green: 0.06, blue: 0.09)
    }

    private func cardSurface(accent: Color) -> some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(.ultraThinMaterial)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.04) : Color.white.opacity(0.6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(accent.opacity(colorScheme == .dark ? 0.4 : 0.25), lineWidth: 1)
            )
            .shadow(color: accent.opacity(colorScheme == .dark ? 0.16 : 0.12), radius: 12, x: 0, y: 8)
    }

    private func sectionHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
            Text(subtitle)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
        }
    }


    private func statChip(label: String, value: String) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .secondary)
            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(colorScheme == .dark ? .white : .primary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.06))
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

private struct DashboardMetric: Identifiable {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let tint: Color

    var id: String { title }
}

private struct DashboardActivityItem: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let timestamp: String
    let icon: String
    let tint: Color
}

private struct PremiumMetricCard: View {
    let metric: DashboardMetric
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                ZStack {
                    Circle()
                        .fill(metric.tint.opacity(0.16))
                        .frame(width: 42, height: 42)
                        .overlay(Circle().stroke(metric.tint.opacity(0.20), lineWidth: 1))

                    Image(systemName: metric.icon)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(metric.tint)
                }

                Spacer()

                Circle()
                    .fill(metric.tint.opacity(0.9))
                    .frame(width: 7, height: 7)
                    .shadow(color: metric.tint.opacity(0.7), radius: 7, x: 0, y: 0)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(metric.value)
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundStyle(primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Text(metric.title)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(secondaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(metric.subtitle)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(mutedText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 132, alignment: .topLeading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(surfaceFill)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [strokeColor.opacity(1.0), metric.tint.opacity(0.20), strokeColor.opacity(0.35)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.26 : 0.10), radius: 16, x: 0, y: 10)
        )
    }

    private var primaryText: Color { colorScheme == .dark ? .white : Color(red: 0.04, green: 0.06, blue: 0.10) }
    private var secondaryText: Color { colorScheme == .dark ? Color.white.opacity(0.76) : Color(red: 0.22, green: 0.28, blue: 0.38) }
    private var mutedText: Color { colorScheme == .dark ? Color.white.opacity(0.44) : Color(red: 0.48, green: 0.53, blue: 0.62) }
    private var surfaceFill: Color { colorScheme == .dark ? Color.white.opacity(0.065) : Color.white.opacity(0.88) }
    private var strokeColor: Color { colorScheme == .dark ? Color.white.opacity(0.16) : Color(red: 0.55, green: 0.64, blue: 0.78).opacity(0.24) }
}

private struct ScheduleTimelineCard: View {
    let title: String
    let eyebrow: String
    let dateText: String
    let detail: String
    let venue: String
    let icon: String
    let tint: Color
    let priority: String
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(tint.opacity(0.15))
                    .frame(width: 54, height: 54)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(tint.opacity(0.22), lineWidth: 1)
                    )

                Image(systemName: icon)
                    .font(.system(size: 21, weight: .bold))
                    .foregroundStyle(tint)
            }

            VStack(alignment: .leading, spacing: 7) {
                HStack(spacing: 8) {
                    Text(eyebrow.uppercased())
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .tracking(0.8)
                        .foregroundStyle(tint)

                    Text(priority)
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .foregroundStyle(secondaryText)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(tint.opacity(0.12)))
                }

                Text(title)
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Text(detail)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(secondaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)

                HStack(spacing: 10) {
                    Label(dateText, systemImage: "clock.fill")
                    Label(venue, systemImage: "location.fill")
                }
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(mutedText)
                .lineLimit(1)
                .minimumScaleFactor(0.68)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .heavy))
                .foregroundStyle(mutedText)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(surfaceFill)
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(strokeColor, lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.24 : 0.10), radius: 16, x: 0, y: 10)
        )
    }

    private var primaryText: Color { colorScheme == .dark ? .white : Color(red: 0.04, green: 0.06, blue: 0.10) }
    private var secondaryText: Color { colorScheme == .dark ? Color.white.opacity(0.62) : Color(red: 0.25, green: 0.31, blue: 0.41) }
    private var mutedText: Color { colorScheme == .dark ? Color.white.opacity(0.44) : Color(red: 0.48, green: 0.53, blue: 0.62) }
    private var surfaceFill: Color { colorScheme == .dark ? Color.white.opacity(0.065) : Color.white.opacity(0.86) }
    private var strokeColor: Color { colorScheme == .dark ? Color.white.opacity(0.10) : Color(red: 0.55, green: 0.64, blue: 0.78).opacity(0.24) }
}

private struct ActivityFeedRow: View {
    let item: DashboardActivityItem
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 13) {
            ZStack {
                Circle()
                    .fill(item.tint.opacity(0.14))
                    .frame(width: 42, height: 42)
                Image(systemName: item.icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(item.tint)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(primaryText)
                    .lineLimit(1)

                Text(item.detail)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(secondaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 7) {
                Circle()
                    .fill(item.tint)
                    .frame(width: 7, height: 7)
                    .shadow(color: item.tint.opacity(0.7), radius: 7, x: 0, y: 0)

                Text(item.timestamp)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(mutedText)
                    .lineLimit(1)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(surfaceFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(strokeColor, lineWidth: 1)
                )
        )
    }

    private var primaryText: Color { colorScheme == .dark ? .white : Color(red: 0.04, green: 0.06, blue: 0.10) }
    private var secondaryText: Color { colorScheme == .dark ? Color.white.opacity(0.52) : Color(red: 0.32, green: 0.38, blue: 0.48) }
    private var mutedText: Color { colorScheme == .dark ? Color.white.opacity(0.42) : Color(red: 0.52, green: 0.56, blue: 0.64) }
    private var surfaceFill: Color { colorScheme == .dark ? Color.white.opacity(0.055) : Color.white.opacity(0.78) }
    private var strokeColor: Color { colorScheme == .dark ? Color.white.opacity(0.08) : Color(red: 0.55, green: 0.64, blue: 0.78).opacity(0.20) }
}

private struct QuickActionTile: View {
    let title: String
    let icon: String
    let tint: Color
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.16))
                    .frame(width: 38, height: 38)

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(tint)
            }

            Text(title)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 64)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(surfaceFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(tint.opacity(0.16), lineWidth: 1)
                )
        )
    }

    private var primaryText: Color { colorScheme == .dark ? Color.white.opacity(0.90) : Color(red: 0.04, green: 0.06, blue: 0.10) }
    private var surfaceFill: Color { colorScheme == .dark ? Color.white.opacity(0.065) : Color.white.opacity(0.82) }
}

private struct CalendarInfoRow: View {
    let title: String
    let detail: String
    let icon: String
    let tint: Color
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(tint.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(tint)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Text(detail)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(secondaryText)
                    .lineLimit(2)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .heavy))
                .foregroundStyle(mutedText)
        }
        .padding(13)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(surfaceFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(strokeColor, lineWidth: 1)
                )
        )
    }

    private var primaryText: Color { colorScheme == .dark ? .white : Color(red: 0.04, green: 0.06, blue: 0.10) }
    private var secondaryText: Color { colorScheme == .dark ? Color.white.opacity(0.54) : Color(red: 0.32, green: 0.38, blue: 0.48) }
    private var mutedText: Color { colorScheme == .dark ? Color.white.opacity(0.32) : Color(red: 0.52, green: 0.56, blue: 0.64) }
    private var surfaceFill: Color { colorScheme == .dark ? Color.white.opacity(0.055) : Color.white.opacity(0.78) }
    private var strokeColor: Color { colorScheme == .dark ? Color.white.opacity(0.08) : Color(red: 0.55, green: 0.64, blue: 0.78).opacity(0.20) }
}

private struct TacticalFieldGraphic: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let field = rect.insetBy(dx: rect.width * 0.05, dy: rect.height * 0.08)
        let midX = field.midX
        let centerRadius = min(field.width, field.height) * 0.14

        path.addRoundedRect(in: field, cornerSize: CGSize(width: 10, height: 10))
        path.move(to: CGPoint(x: midX, y: field.minY))
        path.addLine(to: CGPoint(x: midX, y: field.maxY))
        path.addEllipse(in: CGRect(
            x: midX - centerRadius,
            y: field.midY - centerRadius,
            width: centerRadius * 2,
            height: centerRadius * 2
        ))

        let boxWidth = field.width * 0.18
        let boxHeight = field.height * 0.42
        let leftBox = CGRect(x: field.minX, y: field.midY - boxHeight / 2, width: boxWidth, height: boxHeight)
        let rightBox = CGRect(x: field.maxX - boxWidth, y: field.midY - boxHeight / 2, width: boxWidth, height: boxHeight)
        path.addRect(leftBox)
        path.addRect(rightBox)

        let smallBoxWidth = field.width * 0.08
        let smallBoxHeight = field.height * 0.22
        path.addRect(CGRect(x: field.minX, y: field.midY - smallBoxHeight / 2, width: smallBoxWidth, height: smallBoxHeight))
        path.addRect(CGRect(x: field.maxX - smallBoxWidth, y: field.midY - smallBoxHeight / 2, width: smallBoxWidth, height: smallBoxHeight))

        for point in [
            CGPoint(x: field.minX + field.width * 0.28, y: field.midY),
            CGPoint(x: field.maxX - field.width * 0.28, y: field.midY),
            CGPoint(x: field.minX + field.width * 0.64, y: field.minY + field.height * 0.24),
            CGPoint(x: field.minX + field.width * 0.42, y: field.maxY - field.height * 0.18)
        ] {
            path.addEllipse(in: CGRect(x: point.x - 2, y: point.y - 2, width: 4, height: 4))
        }

        return path
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
                                    .foregroundColor(AppTheme.warning)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .fill(AppTheme.warning.opacity(0.15))
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
                    .cardSurface(cornerRadius: 16)

                    // Game Details
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppTheme.brandAccent)
                            Text("Game Details")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                        }

                        VStack(spacing: 12) {
                            // Date
                            HStack {
                                Image(systemName: "calendar")
                                    .font(.system(size: 14))
                                    .foregroundColor(AppTheme.warning)
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
                                    .foregroundColor(AppTheme.warning)
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
                                        .foregroundColor(AppTheme.success)
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
                                    .foregroundColor(AppTheme.purpleAccent)
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
                    .cardSurface(cornerRadius: 16)

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
                            .foregroundColor(AppTheme.brandAccent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(AppTheme.brandAccent.opacity(0.1))
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
                                            colors: [AppTheme.success, AppTheme.success.opacity(0.8)],
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
            .background(AppBackgroundView())
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
