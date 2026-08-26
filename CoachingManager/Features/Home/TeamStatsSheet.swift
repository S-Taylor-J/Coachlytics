//
//  TeamStatsSheet.swift
//  CoachingManager
//
//  Created by Taylor Santos on 06/01/2026.
//

import SwiftUI

struct TeamStatsSheet: View {
    let games: [Game]
    let teamPlayers: [Player]
    let teamName: String

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedTab = 0

    // MARK: - Computed Properties
    private var wins: Int {
        games.filter { $0.myTeamScore > $0.opponentScore }.count
    }

    private var losses: Int {
        games.filter { $0.myTeamScore < $0.opponentScore }.count
    }

    private var draws: Int {
        games.filter { $0.myTeamScore == $0.opponentScore }.count
    }

    private var winPercentage: Double {
        guard games.count > 0 else { return 0 }
        return Double(wins) / Double(games.count) * 100
    }

    private var totalGoalsFor: Int {
        games.reduce(0) { $0 + $1.myTeamScore }
    }

    private var totalGoalsAgainst: Int {
        games.reduce(0) { $0 + $1.opponentScore }
    }

    private var goalDifference: Int {
        totalGoalsFor - totalGoalsAgainst
    }

    private var goalsPerGameFor: Double {
        games.isEmpty ? 0 : Double(totalGoalsFor) / Double(games.count)
    }

    private var goalsPerGameAgainst: Double {
        games.isEmpty ? 0 : Double(totalGoalsAgainst) / Double(games.count)
    }

    private var totalCircleEntries: Int {
        games.flatMap { $0.events }.filter { $0.eventType == .circleEntry && $0.team == .ourTeam }.count
    }

    private var totalCircleEntriesAgainst: Int {
        games.flatMap { $0.events }.filter { $0.eventType == .circleEntry && $0.team == .otherTeam }.count
    }

    private var totalInfractions: Int {
        games.flatMap { $0.events }.filter { $0.eventType == .infraction && $0.team == .ourTeam }.count
    }

    private var totalOpponentInfractions: Int {
        let allEvents = games.flatMap { $0.events }
        return allEvents.filter { $0.eventType == .infraction && $0.team == .otherTeam }.count
    }

    private var allOurGoalEvents: [GameEvent] {
        let allEvents = games.flatMap { $0.events }
        return allEvents.filter { event in
            let isGoal = event.eventType == .goal || (event.eventType == .circleEntry && event.circleResult == .goal)
            return isGoal && event.team == .ourTeam
        }
    }

    private var goalsFromOpenPlay: Int {
        allOurGoalEvents.filter { $0.goalType == .openPlay || $0.goalType == nil }.count
    }

    private var goalsFromPenaltyCorner: Int {
        allOurGoalEvents.filter { $0.goalType == .penaltyCorner }.count
    }

    private var goalsFromStroke: Int {
        allOurGoalEvents.filter { $0.goalType == .stroke }.count
    }

    private var allTeamEvents: [GameEvent] {
        games.flatMap { $0.events }
    }

    private var shortCornersFor: Int {
        allTeamEvents.filter { $0.circleResult == .penaltyCorner && $0.team == .ourTeam }.count
    }

    private var shortCornersAgainst: Int {
        allTeamEvents.filter { $0.circleResult == .penaltyCorner && $0.team == .otherTeam }.count
    }

    private var shortCornerGoalsFor: Int {
        allTeamEvents.filter {
            $0.team == .ourTeam && $0.goalType == .penaltyCorner && ($0.eventType == .goal || ($0.eventType == .circleEntry && $0.circleResult == .goal))
        }.count
    }

    private var shortCornerGoalsAgainst: Int {
        allTeamEvents.filter {
            $0.team == .otherTeam && $0.goalType == .penaltyCorner && ($0.eventType == .goal || ($0.eventType == .circleEntry && $0.circleResult == .goal))
        }.count
    }

    private func goalCount(for player: Player) -> Int {
        let playerEvents = allTeamEvents.filter { $0.playerId == player.id && $0.team == .ourTeam }
        let goals = playerEvents.filter { event in
            event.eventType == .goal || (event.eventType == .circleEntry && event.circleResult == .goal)
        }
        return goals.count
    }

    private func circleEntryCount(for player: Player) -> Int {
        let playerEvents = allTeamEvents.filter { $0.playerId == player.id && $0.team == .ourTeam }
        return playerEvents.filter { $0.eventType == .circleEntry }.count
    }

    private var topScorers: [(Player, Int)] {
        var results: [(Player, Int)] = []
        for player in teamPlayers {
            let goals = goalCount(for: player)
            if goals > 0 {
                results.append((player, goals))
            }
        }
        return results.sorted { $0.1 > $1.1 }
    }

    private var topCircleEntries: [(Player, Int)] {
        var results: [(Player, Int)] = []
        for player in teamPlayers {
            let entries = circleEntryCount(for: player)
            if entries > 0 {
                results.append((player, entries))
            }
        }
        return results.sorted { $0.1 > $1.1 }
    }

    private var topScorersItems: [(Player, String, Int)] {
        Array(topScorers.prefix(5)).map { ($0.0, "\($0.1) goals", $0.1) }
    }

    private var topCircleEntriesItems: [(Player, String, Int)] {
        Array(topCircleEntries.prefix(5)).map { ($0.0, "\($0.1) entries", $0.1) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {
                        teamHeader
                        tabPicker

                        switch selectedTab {
                        case 0:
                            overviewSection
                        case 1:
                            goalsSection
                        case 2:
                            leaderboardsSection
                        default:
                            overviewSection
                        }
                    }
                    .padding(20)
                    .padding(.bottom, 28)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .black))
                            .foregroundStyle(primaryText)
                            .frame(width: 34, height: 34)
                            .background(
                                Circle()
                                    .fill(themeSurfaceFill)
                                    .overlay(Circle().stroke(themeStroke, lineWidth: 1))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Team Header
    private var teamHeader: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: colorScheme == .dark ? [
                            Color(red: 0.055, green: 0.085, blue: 0.145),
                            Color(red: 0.034, green: 0.075, blue: 0.155),
                            Color(red: 0.014, green: 0.145, blue: 0.320)
                        ] : [
                            Color(red: 0.925, green: 0.960, blue: 1.000),
                            Color(red: 0.830, green: 0.900, blue: 1.000),
                            Color(red: 0.700, green: 0.840, blue: 1.000)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [brandAccent.opacity(0.64), themeStroke, positiveGreen.opacity(0.22)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: brandAccent.opacity(colorScheme == .dark ? 0.24 : 0.18), radius: 26, x: 0, y: 14)

            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [brandAccent, Color(red: 0.17, green: 0.35, blue: 1.0)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 68, height: 68)
                            .shadow(color: brandAccent.opacity(0.34), radius: 16, x: 0, y: 10)

                        Text(teamInitials)
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundStyle(heroPrimaryText)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Team Analytics")
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                            .tracking(1.1)
                            .foregroundStyle(brandAccent)

                        Text(teamName)
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.74)

                        Text("\(games.count) games • \(teamPlayers.count) players")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(textMuted)
                    }

                    Spacer(minLength: 0)
                }

                HStack(spacing: 10) {
                    recordChip(value: "\(wins)W", tint: positiveGreen)
                    recordChip(value: "\(draws)D", tint: drawTint)
                    recordChip(value: "\(losses)L", tint: negativeRed)
                    Spacer()
                    Text(String(format: "%.0f%% win", winPercentage))
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(positiveGreen)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(positiveGreen.opacity(0.13)))
                }
            }
            .padding(20)
        }
    }

    // MARK: - Tab Picker
    private var tabPicker: some View {
        HStack(spacing: 6) {
            ForEach(0..<3) { index in
                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                        selectedTab = index
                    }
                } label: {
                    Text(tabTitle(for: index))
                        .font(.system(size: 13, weight: selectedTab == index ? .black : .bold, design: .rounded))
                        .foregroundStyle(selectedTab == index ? selectedTabText : textMuted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(
                            Capsule()
                                .fill(selectedTab == index ? brandAccent.opacity(0.22) : Color.clear)
                                .overlay(
                                    Capsule()
                                        .stroke(selectedTab == index ? brandAccent.opacity(0.30) : Color.clear, lineWidth: 1)
                                )
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(5)
        .background(
            Capsule()
                .fill(themeSurfaceFill)
                .overlay(Capsule().stroke(themeStroke, lineWidth: 1))
        )
    }

    private func tabTitle(for index: Int) -> String {
        switch index {
        case 0: return "Overview"
        case 1: return "Goals"
        case 2: return "Leaderboards"
        default: return ""
        }
    }

    // MARK: - Overview Section
    private var overviewSection: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 16) {
                sectionTitle("Performance")

                LazyVGrid(columns: statGridColumns, spacing: 12) {
                    TeamStatTile(title: "Win Rate", value: String(format: "%.0f%%", winPercentage), subtitle: "\(games.count) games", icon: "trophy.fill", tint: positiveGreen)
                    TeamStatTile(title: "Goal Diff", value: goalDifference >= 0 ? "+\(goalDifference)" : "\(goalDifference)", subtitle: "\(totalGoalsFor) for / \(totalGoalsAgainst) against", icon: "plus.forwardslash.minus", tint: goalDifference >= 0 ? positiveGreen : negativeRed)
                    TeamStatTile(title: "Scored", value: "\(totalGoalsFor)", subtitle: String(format: "%.1f per game", goalsPerGameFor), icon: "scope", tint: brandAccent)
                    TeamStatTile(title: "Conceded", value: "\(totalGoalsAgainst)", subtitle: String(format: "%.1f per game", goalsPerGameAgainst), icon: "shield.lefthalf.filled", tint: negativeRed)
                }

                segmentedRecordBar
            }
            .padding(16)
            .background(cardSurface(accent: brandAccent))

            VStack(alignment: .leading, spacing: 12) {
                sectionTitle("Season Totals")

                VStack(spacing: 14) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("For Us")
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .foregroundStyle(textMuted)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            CompactTeamStat(title: "Goals For", value: "\(totalGoalsFor)", tint: positiveGreen)
                            CompactTeamStat(title: "Goals / Game", value: String(format: "%.1f", goalsPerGameFor), tint: brandAccent)
                            CompactTeamStat(title: "Circle Entries", value: "\(totalCircleEntries)", tint: Color(red: 0.22, green: 0.82, blue: 1.0))
                            CompactTeamStat(title: "Infractions", value: "\(totalInfractions)", tint: warningOrange)
                            CompactTeamStat(title: "Short Corners", value: "\(shortCornersFor)", tint: Color(red: 0.20, green: 0.86, blue: 0.76))
                            CompactTeamStat(title: "SC Goals", value: "\(shortCornerGoalsFor)", tint: Color(red: 0.90, green: 0.45, blue: 1.0))
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Against Us")
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .foregroundStyle(textMuted)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            CompactTeamStat(title: "Goals Against", value: "\(totalGoalsAgainst)", tint: negativeRed)
                            CompactTeamStat(title: "Goals / Game", value: String(format: "%.1f", goalsPerGameAgainst), tint: brandAccent)
                            CompactTeamStat(title: "Circle Entries", value: "\(totalCircleEntriesAgainst)", tint: Color(red: 0.22, green: 0.82, blue: 1.0))
                            CompactTeamStat(title: "Infractions", value: "\(totalOpponentInfractions)", tint: warningOrange)
                            CompactTeamStat(title: "Short Corners", value: "\(shortCornersAgainst)", tint: Color(red: 0.20, green: 0.86, blue: 0.76))
                            CompactTeamStat(title: "SC Goals", value: "\(shortCornerGoalsAgainst)", tint: Color(red: 0.90, green: 0.45, blue: 1.0))
                        }
                    }
                }
            }
            .padding(16)
            .background(cardSurface(accent: .blue))
        }
    }

    // MARK: - Goals Section
    private var goalsSection: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                sectionTitle("Goal Types")

                VStack(spacing: 10) {
                    GoalTypeRow(type: "Open Play", count: goalsFromOpenPlay, total: totalGoalsFor, color: .blue)
                    GoalTypeRow(type: "Penalty Corner", count: goalsFromPenaltyCorner, total: totalGoalsFor, color: .orange)
                    GoalTypeRow(type: "Stroke", count: goalsFromStroke, total: totalGoalsFor, color: .red)
                }
            }
            .padding(16)
            .background(cardSurface(accent: brandAccent))

            VStack(alignment: .leading, spacing: 12) {
                sectionTitle("Goals per Game")

                if games.isEmpty {
                    HStack {
                        Spacer()
                        Text("No games yet")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(textMuted)
                            .padding(.vertical, 20)
                        Spacer()
                    }
                } else {
                    VStack(spacing: 8) {
                        ForEach(games) { game in
                            GoalGameRow(game: game)
                        }
                    }
                }
            }
            .padding(16)
            .background(cardSurface(accent: warningOrange))
        }
    }

    // MARK: - Leaderboards Section
    private var leaderboardsSection: some View {
        VStack(spacing: 16) {
            premiumLeaderboard(title: "Top Scorers", icon: "scope", tint: brandAccent, items: topScorersItems)
            premiumLeaderboard(title: "Most Circle Entries", icon: "arrow.up.forward.circle.fill", tint: positiveGreen, items: topCircleEntriesItems)
        }
    }

    // MARK: - Styling Helpers
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
                    brandAccent.opacity(colorScheme == .dark ? 0.13 : 0.16),
                    Color.clear,
                    positiveGreen.opacity(colorScheme == .dark ? 0.05 : 0.10)
                ],
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
        }
    }

    private var statGridColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]
    }

    private var brandAccent: Color {
        Color(red: 0.42, green: 0.70, blue: 1.0)
    }

    private var positiveGreen: Color {
        Color(red: 0.16, green: 0.92, blue: 0.59)
    }

    private var warningOrange: Color {
        Color(red: 1.0, green: 0.62, blue: 0.22)
    }

    private var negativeRed: Color {
        Color(red: 1.0, green: 0.36, blue: 0.32)
    }

    private var textMuted: Color {
        colorScheme == .dark ? Color.white.opacity(0.54) : Color(red: 0.45, green: 0.50, blue: 0.60)
    }

    private var primaryText: Color {
        colorScheme == .dark ? .white : Color(red: 0.035, green: 0.055, blue: 0.090)
    }

    private var heroPrimaryText: Color {
        colorScheme == .dark ? .white : Color(red: 0.030, green: 0.055, blue: 0.105)
    }

    private var themeSurfaceFill: Color {
        colorScheme == .dark ? Color.white.opacity(0.070) : Color.white.opacity(0.86)
    }

    private var themeSecondarySurfaceFill: Color {
        colorScheme == .dark ? Color.white.opacity(0.055) : Color.white.opacity(0.76)
    }

    private var themeStroke: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color(red: 0.55, green: 0.64, blue: 0.78).opacity(0.24)
    }

    private var selectedTabText: Color {
        colorScheme == .dark ? .white : Color(red: 0.035, green: 0.055, blue: 0.090)
    }

    private var drawTint: Color {
        colorScheme == .dark ? Color.white.opacity(0.48) : Color(red: 0.45, green: 0.50, blue: 0.60)
    }

    private var teamInitials: String {
        let words = teamName.split(separator: " ")
        let initials = words.prefix(2).compactMap { $0.first }.map(String.init).joined()
        return initials.isEmpty ? "CL" : initials.uppercased()
    }

    private var segmentedRecordBar: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Record Split")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(textMuted)
                Spacer()
                Text("\(wins)-\(draws)-\(losses)")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(primaryText.opacity(0.82))
            }

            GeometryReader { geo in
                HStack(spacing: 3) {
                    Rectangle()
                        .fill(positiveGreen)
                        .frame(width: geo.size.width * CGFloat(wins) / max(CGFloat(games.count), 1), height: 10)

                    Rectangle()
                        .fill(drawTint)
                        .frame(width: geo.size.width * CGFloat(draws) / max(CGFloat(games.count), 1), height: 10)

                    Rectangle()
                        .fill(negativeRed)
                        .frame(width: geo.size.width * CGFloat(losses) / max(CGFloat(games.count), 1), height: 10)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(themeStroke.opacity(0.55))
                .clipShape(Capsule())
            }
            .frame(height: 10)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(colorScheme == .dark ? Color.black.opacity(0.18) : Color.white.opacity(0.70))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(themeStroke, lineWidth: 1)
                )
        )
    }

    private func sectionTitle(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(primaryText)
            Spacer()
        }
    }

    private func recordChip(value: String, tint: Color) -> some View {
        Text(value)
            .font(.system(size: 12, weight: .black, design: .rounded))
            .foregroundStyle(colorScheme == .dark ? .white : Color(red: 0.035, green: 0.055, blue: 0.090))
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(tint.opacity(0.16))
                    .overlay(Capsule().stroke(tint.opacity(0.18), lineWidth: 1))
            )
    }

    private func premiumLeaderboard(title: String, icon: String, tint: Color, items: [(Player, String, Int)]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .black))
                    .foregroundStyle(tint)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(tint.opacity(0.14)))

                sectionTitle(title)
            }

            if items.isEmpty {
                Text("No player data yet")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(textMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(items.enumerated()), id: \.element.0.id) { index, item in
                        HStack(spacing: 12) {
                            Text("\(index + 1)")
                                .font(.system(size: 12, weight: .black, design: .rounded))
                                .foregroundStyle(tint)
                                .frame(width: 28, height: 28)
                                .background(Circle().fill(tint.opacity(0.14)))

                            VStack(alignment: .leading, spacing: 3) {
                                Text(item.0.name)
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundStyle(primaryText)
                                Text("#\(item.0.number)")
                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                                    .foregroundStyle(textMuted)
                            }

                            Spacer()

                            Text(item.1)
                                .font(.system(size: 13, weight: .black, design: .rounded))
                                .foregroundStyle(primaryText.opacity(0.86))
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(themeSecondarySurfaceFill)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(themeStroke, lineWidth: 1)
                                )
                        )
                    }
                }
            }
        }
        .padding(16)
        .background(cardSurface(accent: tint))
    }

    private func cardSurface(accent: Color) -> some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(.ultraThinMaterial)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(themeSurfaceFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(accent.opacity(0.22), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.24 : 0.10), radius: 16, x: 0, y: 10)
    }
}

private struct TeamStatTile: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let tint: Color
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .black))
                    .foregroundStyle(tint)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(tint.opacity(0.14)))
                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 27, weight: .black, design: .rounded))
                    .foregroundStyle(primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Text(title)
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(secondaryText)

                Text(subtitle)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(mutedText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 124, alignment: .topLeading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(surfaceFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(tint.opacity(0.16), lineWidth: 1)
                )
        )
    }

    private var primaryText: Color { colorScheme == .dark ? .white : Color(red: 0.04, green: 0.06, blue: 0.10) }
    private var secondaryText: Color { colorScheme == .dark ? Color.white.opacity(0.74) : Color(red: 0.22, green: 0.28, blue: 0.38) }
    private var mutedText: Color { colorScheme == .dark ? Color.white.opacity(0.44) : Color(red: 0.48, green: 0.53, blue: 0.62) }
    private var surfaceFill: Color { colorScheme == .dark ? Color.white.opacity(0.060) : Color.white.opacity(0.78) }
}

private struct CompactTeamStat: View {
    let title: String
    let value: String
    let tint: Color
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(tint)
                .frame(width: 7, height: 7)
                .shadow(color: tint.opacity(0.55), radius: 6, x: 0, y: 0)

            VStack(alignment: .leading, spacing: 3) {
                Text(value)
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(primaryText)
                Text(title)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(mutedText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .fill(surfaceFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .stroke(strokeColor, lineWidth: 1)
                )
        )
    }

    private var primaryText: Color { colorScheme == .dark ? .white : Color(red: 0.04, green: 0.06, blue: 0.10) }
    private var mutedText: Color { colorScheme == .dark ? Color.white.opacity(0.48) : Color(red: 0.48, green: 0.53, blue: 0.62) }
    private var surfaceFill: Color { colorScheme == .dark ? Color.white.opacity(0.052) : Color.white.opacity(0.74) }
    private var strokeColor: Color { colorScheme == .dark ? Color.white.opacity(0.07) : Color(red: 0.55, green: 0.64, blue: 0.78).opacity(0.20) }
}
