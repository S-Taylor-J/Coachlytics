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
    
    private var totalCircleEntries: Int {
        games.flatMap { $0.events }.filter { $0.eventType == .circleEntry && $0.team == .ourTeam }.count
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
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
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
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Team Stats")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Team Header
    private var teamHeader: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 70, height: 70)
                
                Image(systemName: "sportscourt.fill")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(teamName)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                
                Text("\(games.count) games played")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                
                HStack(spacing: 8) {
                    StatPill(value: "\(wins)W", color: .green)
                    StatPill(value: "\(draws)D", color: .gray)
                    StatPill(value: "\(losses)L", color: .red)
                }
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 8, x: 0, y: 4)
        )
    }
    
    // MARK: - Tab Picker
    private var tabPicker: some View {
        HStack(spacing: 0) {
            ForEach(0..<3) { index in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = index
                    }
                } label: {
                    VStack(spacing: 6) {
                        Text(tabTitle(for: index))
                            .font(.system(size: 13, weight: selectedTab == index ? .semibold : .medium, design: .rounded))
                            .foregroundColor(selectedTab == index ? .blue : .secondary)
                        
                        Rectangle()
                            .fill(selectedTab == index ? Color.blue : Color.clear)
                            .frame(height: 2)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 8, x: 0, y: 4)
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
            // Win rate card
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "percent")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.green)
                    Text("Win Rate")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                    Spacer()
                }
                
                HStack(alignment: .bottom, spacing: 8) {
                    Text(String(format: "%.0f%%", winPercentage))
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(.green)
                    
                    Text("of \(games.count) games")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.bottom, 8)
                    
                    Spacer()
                }
                
                // Win rate bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.systemGray5))
                            .frame(height: 8)
                        
                        HStack(spacing: 0) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.green)
                                .frame(width: geo.size.width * CGFloat(wins) / max(CGFloat(games.count), 1), height: 8)
                            
                            RoundedRectangle(cornerRadius: 0)
                                .fill(Color.gray)
                                .frame(width: geo.size.width * CGFloat(draws) / max(CGFloat(games.count), 1), height: 8)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.red)
                                .frame(width: geo.size.width * CGFloat(losses) / max(CGFloat(games.count), 1), height: 8)
                        }
                    }
                }
                .frame(height: 8)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 8, x: 0, y: 4)
            )
            
            // Goals overview
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "soccerball")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.purple)
                    Text("Goals")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                    Spacer()
                }
                
                HStack(spacing: 16) {
                    VStack(spacing: 4) {
                        Text("\(totalGoalsFor)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.purple)
                        Text("Scored")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    
                    VStack(spacing: 4) {
                        Text("\(totalGoalsAgainst)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.red)
                        Text("Conceded")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    
                    VStack(spacing: 4) {
                        Text(goalDifference >= 0 ? "+\(goalDifference)" : "\(goalDifference)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(goalDifference >= 0 ? .green : .red)
                        Text("Difference")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
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
            
            // Other stats
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.blue)
                    Text("Season Totals")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                    Spacer()
                }
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    StatBox(title: "Circle Entries", value: "\(totalCircleEntries)", color: .green)
                    StatBox(title: "Our Infractions", value: "\(totalInfractions)", color: .orange)
                    StatBox(title: "Goals per Game", value: String(format: "%.1f", games.count > 0 ? Double(totalGoalsFor) / Double(games.count) : 0), color: .purple)
                    StatBox(title: "Opponent Infractions", value: "\(totalOpponentInfractions)", color: .teal)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 8, x: 0, y: 4)
            )
        }
    }
    
    // MARK: - Goals Section
    private var goalsSection: some View {
        VStack(spacing: 16) {
            // Goal types breakdown
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "chart.pie.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.purple)
                    Text("Goal Types")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                    Spacer()
                }
                
                VStack(spacing: 10) {
                    GoalTypeRow(type: "Open Play", count: goalsFromOpenPlay, total: totalGoalsFor, color: .blue)
                    GoalTypeRow(type: "Penalty Corner", count: goalsFromPenaltyCorner, total: totalGoalsFor, color: .orange)
                    GoalTypeRow(type: "Stroke", count: goalsFromStroke, total: totalGoalsFor, color: .red)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 8, x: 0, y: 4)
            )
            
            // Game by game goals
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "list.bullet.rectangle")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.orange)
                    Text("Goals per Game")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                    Spacer()
                }
                
                if games.isEmpty {
                    HStack {
                        Spacer()
                        Text("No games yet")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
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
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 8, x: 0, y: 4)
            )
        }
    }
    
    // MARK: - Leaderboards Section
    private var leaderboardsSection: some View {
        VStack(spacing: 16) {
            LeaderboardCard(
                title: "Top Scorers",
                icon: "soccerball",
                color: .purple,
                items: topScorersItems
            )
            
            LeaderboardCard(
                title: "Most Circle Entries",
                icon: "circle.circle.fill",
                color: .green,
                items: topCircleEntriesItems
            )
        }
    }
}
