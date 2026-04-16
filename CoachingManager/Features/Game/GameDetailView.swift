//
//  GameDetailView.swift
//  CoachingManager
//
//  Created by Taylor Santos on 07/01/2026.
//

import SwiftUI
import SwiftData
import Combine

// MARK: - Game Detail View
struct GameDetailView: View {
    @Bindable var game: Game
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("activeGameId") private var activeGameId: String = ""
    @Query(sort: \Player.number) private var allPlayers: [Player]
    @Query(sort: \Team.name) private var teams: [Team]
    
    @StateObject private var gameTimer: GameTimer
    
    @State private var showEventForm = false
    @State private var selectedLocation: CGPoint = .zero
    @State private var filterTeam: TeamType?
    @State private var filterEventType: EventType?
    @State private var filterCircleResult: CircleResult?
    @State private var selectedQuarterFilter: Int? = nil // nil = all quarters, number = specific quarter
    @State private var showQuarterSummary = false
    
    // Multi-step form state
    @State private var currentStep = 0
    @State private var selectedEventType: EventType = .infraction
    @State private var selectedTeam: TeamType = .ourTeam
    @State private var selectedPlayerId: UUID?
    @State private var selectedInfraction: InfractionType = .minor
    @State private var selectedCardType: CardType = .none
    @State private var selectedCircleResult: CircleResult = .nothing
    @State private var selectedGoalType: GoalType = .openPlay
    
    // Game settings for form behavior
    @State private var gameSettings = GameSettings()
    
    // Event highlighting and repositioning state
    @State private var highlightedEventId: UUID? = nil
    
    // Recent events display format
    @State private var showEventsAsList: Bool = false
    
    // Edit game sheet
    @State private var showEditGameSheet = false

    private let pitchAspectRatio: CGFloat = 2.0/3.0
    private let recentEventsMaxRows: CGFloat = 10
    
    // Players available for this game
    private var gamePlayers: [Player] {
        if game.hasSelectedPlayerSelection {
            let selectedIds = Set(game.selectedPlayerIds)
            return allPlayers
                .filter { selectedIds.contains($0.id) }
                .sorted { $0.number < $1.number }
        }
        guard let myTeamId = game.myTeamId,
              let myTeam = teams.first(where: { $0.id == myTeamId }) else {
            return []
        }
        return myTeam.players.sorted { $0.number < $1.number }
    }
    
    // Filtered events based on team, event type, and quarter selection
    private var filteredEvents: [GameEvent] {
        var events = game.events
        
        // Filter by quarter
        if let quarter = selectedQuarterFilter {
            events = events.filter { $0.quarter == quarter }
        }
        
        // Filter by team
        if let team = filterTeam {
            events = events.filter { $0.team == team }
        }
        
        // Filter by event type
        if let eventType = filterEventType {
            events = events.filter { $0.eventType == eventType }
        }
        
        // Filter by circle result (only applies to circle entry events)
        if let circleResult = filterCircleResult {
            events = events.filter { $0.circleResult == circleResult }
        }
        
        return events
    }
    
    // Events for current quarter only (for live play)
    private var currentQuarterEvents: [GameEvent] {
        var events = game.currentQuarterEvents
        if let team = filterTeam {
            events = events.filter { $0.team == team }
        }
        if let eventType = filterEventType {
            events = events.filter { $0.eventType == eventType }
        }
        if let circleResult = filterCircleResult {
            events = events.filter { $0.circleResult == circleResult }
        }
        return events
    }

    private var sortedRecentEvents: [GameEvent] {
        filteredEvents.sorted { eventSortKey($0) > eventSortKey($1) }
    }

    private var recentEventsListMaxHeight: CGFloat {
        recentEventsMaxRows * 68
    }
    
    // Subtitle for recent events based on current filters
    private var recentEventsSubtitle: String {
        var parts: [String] = []
        
        if let quarter = selectedQuarterFilter {
            parts.append("Quarter \(quarter)")
        } else {
            parts.append("All quarters")
        }
        
        if let team = filterTeam {
            parts.append(team == .ourTeam ? "Our team" : "Opponent")
        }
        
        if let eventType = filterEventType {
            parts.append(eventType.rawValue)
        }
        
        if let circleResult = filterCircleResult {
            parts.append(circleResult.rawValue)
        }
        
        return parts.joined(separator: " • ")
    }
    
    init(game: Game) {
        self._game = Bindable(wrappedValue: game)
        // Use singleton timer service - timer persists even when view is dismissed
        self._gameTimer = StateObject(wrappedValue: GameTimerService.shared.timer(for: game))
    }
    
    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // MARK: - Game Info Header
                    gameInfoHeader
                        .padding(.horizontal, 20)
                    
                    // MARK: - Game Clock Card
                    GameClockCard2(
                        gameTimer: gameTimer,
                        gameId: game.id,
                        isCompleted: game.isCompleted,
                        onSaveState: saveGameState,
                        onEndQuarter: handleEndQuarter,
                        onEndGame: endGame
                    )
                    .padding(.horizontal, 20)
                    
                    // MARK: - Score Card
                    ScoreCard2(
                        myTeamName: game.myTeamName,
                        opponentName: game.opponentName,
                        myTeamScore: game.myTeamScore,
                        opponentScore: game.opponentScore,
                        isCompleted: game.isCompleted,
                        onReset: resetScores
                    )
                    .padding(.horizontal, 20)
                    
                    // MARK: - Quarter Filter Pills
                    quarterFilterView
                        .padding(.horizontal, 20)
                    
                    // MARK: - Team Filter Pills
                    FilterView(selectedTeam: $filterTeam, selectedEventType: $filterEventType, selectedCircleResult: $filterCircleResult)
                    
                    // MARK: - Pitch with tap gesture
                    pitchCard
                        .padding(.horizontal, 20)
                    
                    // MARK: - Analytics Section
                    analyticsSection
                        .padding(.horizontal, 20)
                    
                    // MARK: - Recent Events
                    recentEventsSection
                        .padding(.horizontal, 20)
                }
                .padding(.vertical, 16)
                .padding(.bottom, 60)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 0) {
                    Text(game.myTeamName)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                    Text("vs \(game.opponentName)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showEditGameSheet = true
                    } label: {
                        Label("Edit Game Details", systemImage: "pencil")
                    }
                    
                    Button {
                        endGame()
                    } label: {
                        Label("End Game", systemImage: "flag.checkered")
                    }
                    .disabled(game.isCompleted)
                    
                    Button(role: .destructive) {
                        clearAllEvents()
                    } label: {
                        Label("Clear Events", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 18))
                }
            }
        }
        .sheet(isPresented: $showEditGameSheet) {
            EditGameSheet(game: game, teams: Array(teams))
        }
        .sheet(isPresented: $showEventForm) {
            MultiStepFormView(
                currentStep: $currentStep,
                selectedEventType: $selectedEventType,
                selectedTeam: $selectedTeam,
                selectedPlayerId: $selectedPlayerId,
                selectedInfraction: $selectedInfraction,
                selectedCardType: $selectedCardType,
                selectedCircleResult: $selectedCircleResult,
                selectedGoalType: $selectedGoalType,
                players: gamePlayers,
                requirePlayerForInfractions: gameSettings.requirePlayerForInfractions,
                requirePlayerForCircleEntry: gameSettings.requirePlayerForCircleEntry,
                requirePlayerForTurnover: gameSettings.requirePlayerForTurnover,
                onSave: saveEvent,
                onCancel: cancelEvent
            )
        }
        .onAppear {
            PlayerTimeService.shared.track(game: game)
            if game.isGameActive || game.isRunning {
                activeGameId = game.id.uuidString
                PlayerTimeService.shared.ensureActiveStintsFromDefaults(gameId: game.id)
            }
            // Load game settings
            if let settingsString = UserDefaults.standard.string(forKey: "gameSettingsData"),
               let data = settingsString.data(using: .utf8),
               let settings = try? JSONDecoder().decode(GameSettings.self, from: data) {
                gameSettings = settings
            }
            
            // Set up save callback for timer
            gameTimer.onSave { [weak modelContext] timer in
                guard let context = modelContext else { return }
                game.isGameActive = timer.isGameActive
                game.isRunning = timer.isRunning
                game.currentQuarter = timer.currentQuarter
                game.elapsedTime = timer.elapsedTime
                game.quarterElapsedTime = timer.quarterElapsedTime
                try? context.save()
            }
        }
        .onDisappear {
            saveGameState()
        }
    }
    
    // MARK: - Background
    private var backgroundGradient: some View {
        backgroundColor
    }

    private var backgroundColor: Color {
        colorScheme == .dark ? Color(red: 0.05, green: 0.06, blue: 0.09) : Color(red: 0.97, green: 0.98, blue: 1.0)
    }
    
    // MARK: - Game Info Header
    private var gameInfoHeader: some View {
        HStack(spacing: 12) {
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
            
            HStack(spacing: 4) {
                Image(systemName: "calendar")
                    .font(.system(size: 10))
                Text(game.formattedDate)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Quarter Filter View
    private var quarterFilterView: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header with context info
            HStack(alignment: .center) {
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
                        
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Timeline")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                        Text(selectedQuarterFilter == nil ? "Viewing all quarters" : "Viewing Q\(selectedQuarterFilter!)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Current quarter indicator
                if !game.isCompleted {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                        Text("Q\(gameTimer.currentQuarter) Live")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(.green)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(Color.green.opacity(0.12))
                    )
                }
            }
            
            // Quarter pills with visual improvements
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    // All Game option
                    QuarterPill(
                        title: "All",
                        subtitle: "Game",
                        count: game.events.count,
                        isSelected: selectedQuarterFilter == nil,
                        gradientColors: [.purple, .indigo],
                        isDisabled: false,
                        isLive: false
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedQuarterFilter = nil
                        }
                    }
                    
                    // Visual separator
                    Rectangle()
                        .fill(Color(.systemGray4))
                        .frame(width: 1, height: 36)
                        .padding(.horizontal, 4)
                    
                    // Quarter options
                    ForEach(1...game.quarters, id: \.self) { quarter in
                        let isCurrentQuarter = quarter == gameTimer.currentQuarter && !game.isCompleted
                        let isPastQuarter = quarter < gameTimer.currentQuarter || game.isCompleted
                        let isFutureQuarter = quarter > gameTimer.currentQuarter && !game.isCompleted
                        
                        QuarterPill(
                            title: "Q\(quarter)",
                            subtitle: quarterSubtitle(for: quarter),
                            count: game.events(forQuarter: quarter).count,
                            isSelected: selectedQuarterFilter == quarter,
                            gradientColors: isPastQuarter ? [.blue, .cyan] : (isCurrentQuarter ? [.green, .mint] : [.gray, .gray.opacity(0.7)]),
                            isDisabled: isFutureQuarter,
                            isLive: isCurrentQuarter
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedQuarterFilter = quarter
                            }
                        }
                    }
                }
                .padding(.horizontal, 2)
            }
            
            // Quick stats for selected filter
            if let quarter = selectedQuarterFilter {
                quarterQuickStats(for: quarter)
            }
        }
        .padding(16)
        .background(
            GameDetailCardSurface(accent: .purple)
        )
    }
    
    // Helper function for quarter subtitle
    private func quarterSubtitle(for quarter: Int) -> String {
        if game.isCompleted {
            return "Done"
        } else if quarter < gameTimer.currentQuarter {
            return "Done"
        } else if quarter == gameTimer.currentQuarter {
            return "Now"
        } else {
            return "Soon"
        }
    }

    private func eventSortKey(_ event: GameEvent) -> TimeInterval {
        event.gameClockTime ?? event.timestamp.timeIntervalSinceReferenceDate
    }
    
    // Quick stats view for selected quarter
    private func quarterQuickStats(for quarter: Int) -> some View {
        let quarterEvents = game.events(forQuarter: quarter)
        let infractions = quarterEvents.filter { $0.eventType == .infraction }.count
        let circleEntries = quarterEvents.filter { $0.eventType == .circleEntry }.count
        let goals = quarterEvents.filter { $0.eventType == .goal || ($0.eventType == .circleEntry && $0.circleResult == .goal) }.count
        
        return HStack(spacing: 16) {
            QuickStatBadge(icon: "flag.fill", value: quarterEvents.count, label: "Events", color: .blue)
            QuickStatBadge(icon: "exclamationmark.triangle.fill", value: infractions, label: "Fouls", color: .orange)
            QuickStatBadge(icon: "circle.dashed", value: circleEntries, label: "Circles", color: .green)
            QuickStatBadge(icon: "soccerball", value: goals, label: "Goals", color: .purple)
        }
        .padding(.top, 8)
        .padding(.horizontal, 4)
    }
    
    // MARK: - Pitch Card
    private var pitchCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: highlightedEventId != nil ? "arrow.up.and.down.and.arrow.left.and.right" : "sportscourt.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: highlightedEventId != nil ? [.blue, .purple] : [.green, .mint],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .animation(.easeInOut(duration: 0.2), value: highlightedEventId != nil)
                Text(highlightedEventId != nil ? "Use arrows to reposition" : "Tap to Record Event")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .animation(.easeInOut(duration: 0.2), value: highlightedEventId != nil)
                Spacer()
                
                if highlightedEventId != nil {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { highlightedEventId = nil }
                    } label: {
                        Text("Done")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.blue)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(Color.blue.opacity(0.12)))
                    }
                } else {
                    Text("\(filteredEvents.count) events")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            
            GeometryReader { geo in
                let pitchSize = geo.size
                ZStack {
                    PitchBackgroundImageView()
                    
                    ForEach(filteredEvents) { event in
                        let isHighlighted = highlightedEventId == event.id
                        EventMarkerView(
                            event: event,
                            isHighlighted: isHighlighted,
                            isFaded: highlightedEventId != nil && !isHighlighted
                        )
                        .allowsHitTesting(isHighlighted) // only the selected marker is draggable
                        .gesture(
                            isHighlighted ? DragGesture(minimumDistance: 1)
                                .onChanged { value in
                                    guard let index = game.events.firstIndex(where: { $0.id == event.id }) else { return }
                                    let newX = min(max(value.location.x, 0), pitchSize.width)
                                    let newY = min(max(value.location.y, 0), pitchSize.height)
                                    game.events[index].location = CGPoint(x: newX, y: newY)
                                }
                                .onEnded { _ in
                                    saveGameState()
                                    let generator = UIImpactFeedbackGenerator(style: .medium)
                                    generator.impactOccurred()
                                }
                            : nil
                        )
                    }
                    
                    // Decorative arrows hint when an event is selected
                    if let id = highlightedEventId,
                       let event = game.events.first(where: { $0.id == id }) {
                        MarkerMoveControls(
                            position: event.location,
                            pitchSize: pitchSize
                        )
                    }
                    
                    if (filterTeam != nil || filterEventType != nil || filterCircleResult != nil) && !filteredEvents.isEmpty {
                        HeatmapOverlay(events: filteredEvents, pitchSize: pitchSize)
                            .opacity(0.25)
                            .allowsHitTesting(false)
                    }
                }
                .frame(width: pitchSize.width, height: pitchSize.height)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .contentShape(Rectangle())
                .onTapGesture { location in
                    guard !game.isCompleted else { return }
                    if highlightedEventId != nil {
                        withAnimation(.easeInOut(duration: 0.2)) { highlightedEventId = nil }
                        return
                    }
                    selectedLocation = location
                    currentStep = 0
                    showEventForm = true
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                }
                .opacity(game.isCompleted ? 0.7 : 1.0)
            }
            .aspectRatio(pitchAspectRatio, contentMode: .fit)
        }
        .padding(.top, 16)
        .background(
            GameDetailCardSurface(accent: .green)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Analytics Section
    private var analyticsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 28, height: 28)
                        
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Analytics")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                        Text(selectedQuarterFilter == nil ? "Full game stats" : "Q\(selectedQuarterFilter!) stats")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                AnalyticsStatCard(
                    title: "Events",
                    value: "\(filteredEvents.count)",
                    icon: "flag.fill",
                    color: .blue
                )
                
                AnalyticsStatCard(
                    title: "Infractions",
                    value: "\(filteredEvents.filter { $0.eventType == .infraction }.count)",
                    icon: "exclamationmark.triangle.fill",
                    color: .orange
                )
                
                AnalyticsStatCard(
                    title: "Circle Entries",
                    value: "\(filteredEvents.filter { $0.eventType == .circleEntry }.count)",
                    icon: "circle.dashed",
                    color: .green
                )
            }
            
            if !filteredEvents.isEmpty {
                Divider()
                    .padding(.vertical, 4)
                
                InfractionBreakdownCard(events: filteredEvents)
                CircleEntryAnalysisCard(events: filteredEvents)
            }
        }
        .padding(16)
        .background(
            GameDetailCardSurface(accent: .blue)
        )
    }
    
    // MARK: - Recent Events Section
    private var recentEventsSection: some View {
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
                        
                        Image(systemName: "clock.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Recent Events")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                        
                        // Show context of filter
                        Text(recentEventsSubtitle)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Event count badge
                if !filteredEvents.isEmpty {
                    Text("\(filteredEvents.count)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [.orange, .red],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                }
                
                // View mode toggle button
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showEventsAsList.toggle()
                    }
                } label: {
                    Image(systemName: showEventsAsList ? "rectangle.grid.1x2.fill" : "list.bullet")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.white.opacity(0.8))
                        )
                }
            }
            
            if filteredEvents.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color(.systemGray6))
                                .frame(width: 56, height: 56)
                            Image(systemName: "plus.circle.dashed")
                                .font(.system(size: 28, weight: .light))
                                .foregroundColor(.secondary.opacity(0.6))
                        }
                        
                        VStack(spacing: 4) {
                            Text(game.events.isEmpty ? "No events recorded" : "No events for this filter")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(.secondary)
                            Text(game.events.isEmpty ? "Tap the pitch to record your first event" : "Try selecting a different quarter or team")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary.opacity(0.7))
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.vertical, 28)
                    Spacer()
                }
            } else {
                if showEventsAsList {
                    // List view format
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(sortedRecentEvents) { event in
                                EventListRowView(
                                    event: event,
                                    players: gamePlayers,
                                    isHighlighted: highlightedEventId == event.id,
                                    isFaded: highlightedEventId != nil && highlightedEventId != event.id,
                                    onDelete: { deleteEvent(event) }
                                )
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        if highlightedEventId == event.id {
                                            highlightedEventId = nil
                                        } else {
                                            highlightedEventId = event.id
                                        }
                                    }
                                    let generator = UIImpactFeedbackGenerator(style: .light)
                                    generator.impactOccurred()
                                }
                            }
                        }
                    }
                    .frame(maxHeight: recentEventsListMaxHeight)
                } else {
                    // Card view format (horizontal scroll)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(sortedRecentEvents) { event in
                                EventCardView(
                                    event: event,
                                    players: gamePlayers,
                                    isHighlighted: highlightedEventId == event.id,
                                    isFaded: highlightedEventId != nil && highlightedEventId != event.id,
                                    onDelete: { deleteEvent(event) }
                                )
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        if highlightedEventId == event.id {
                                            highlightedEventId = nil
                                        } else {
                                            highlightedEventId = event.id
                                        }
                                    }
                                    let generator = UIImpactFeedbackGenerator(style: .light)
                                    generator.impactOccurred()
                                }
                            }
                        }
                        .padding(.horizontal, 2)
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .padding(16)
        .background(
            GameDetailCardSurface(accent: .orange)
        )
    }
    
    // MARK: - Event Functions
    private func saveEvent() {
        // Determine if player should be recorded (nil means skip)
        let shouldRecordPlayer: Bool
        
        switch selectedEventType {
        case .infraction:
            shouldRecordPlayer = selectedTeam == .ourTeam && 
                gameSettings.requirePlayerForInfractions && 
                selectedPlayerId != nil
        case .circleEntry:
            shouldRecordPlayer = selectedTeam == .ourTeam && 
                gameSettings.requirePlayerForCircleEntry && 
                selectedPlayerId != nil
        case .turnover:
            shouldRecordPlayer = selectedTeam == .ourTeam && 
                gameSettings.requirePlayerForTurnover && 
                selectedPlayerId != nil
        case .goal:
            shouldRecordPlayer = selectedTeam == .ourTeam && 
                selectedPlayerId != nil
        }
        
        let newEvent = GameEvent(
            gameClockTime: gameTimer.elapsedTime, location: selectedLocation,
            eventType: selectedEventType,
            team: selectedTeam,
            playerId: shouldRecordPlayer ? selectedPlayerId : nil,
            infractionType: selectedEventType == .infraction ? selectedInfraction : nil,
            cardType: selectedEventType == .infraction ? selectedCardType : nil,
            circleResult: selectedEventType == .circleEntry ? selectedCircleResult : nil,
            goalType: selectedEventType == .goal ? selectedGoalType : nil,
            quarter: gameTimer.currentQuarter // Save the current quarter with the event
        )
        
        // Update score if it's a goal
        if newEvent.eventType == .goal ||
           (newEvent.eventType == .circleEntry && newEvent.circleResult == .goal) {
            if newEvent.team == .ourTeam {
                game.myTeamScore += 1
            } else {
                game.opponentScore += 1
            }
        }
        
        game.addEvent(newEvent)
        saveGameState()
        resetForm()
        showEventForm = false
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    private func cancelEvent() {
        resetForm()
        showEventForm = false
    }
    
    private func resetForm() {
        currentStep = 0
        selectedEventType = .infraction
        selectedTeam = .ourTeam
        selectedPlayerId = gamePlayers.first?.id
        selectedInfraction = .minor
        selectedCardType = .none
        selectedCircleResult = .nothing
        selectedGoalType = .openPlay
    }
    
    private func saveGameState() {
        game.isGameActive = gameTimer.isGameActive
        game.isRunning = gameTimer.isRunning
        game.currentQuarter = gameTimer.currentQuarter
        game.elapsedTime = gameTimer.elapsedTime
        game.quarterElapsedTime = gameTimer.quarterElapsedTime
        
        try? modelContext.save()
    }
    
    // Handle end of quarter - show summary
    private func handleEndQuarter() {
        let endedQuarter = gameTimer.currentQuarter
        let quarterEvents = game.events(forQuarter: endedQuarter)
        _ = quarterEvents.filter { $0.eventType == .infraction }.count
        
        // Persist stints so quarter transition is saved
        PlayerTimeService.shared.persistStints(to: game)
        
        // Save game state
        saveGameState()
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Auto-select the ended quarter to show its events
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            selectedQuarterFilter = endedQuarter
        }
    }
    
    private func resetScores() {
        guard !game.isCompleted else { return } // Don't allow reset if completed
        game.myTeamScore = 0
        game.opponentScore = 0
        saveGameState()
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
    
    private func endGame() {
        gameTimer.endGame()
        game.isCompleted = true
        saveGameState()
        // Remove timer from service when game ends
        GameTimerService.shared.removeTimer(for: game.id)
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    private func clearAllEvents() {
        game.events = []
        game.myTeamScore = 0
        game.opponentScore = 0
        saveGameState()
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
    
    private func deleteEvent(_ event: GameEvent) {
        // Reverse score if it was a goal
        if event.eventType == .goal || (event.eventType == .circleEntry && event.circleResult == .goal) {
            if event.team == .ourTeam {
                game.myTeamScore = max(0, game.myTeamScore - 1)
            } else {
                game.opponentScore = max(0, game.opponentScore - 1)
            }
        }
        game.events.removeAll { $0.id == event.id }
        if highlightedEventId == event.id { highlightedEventId = nil }
        saveGameState()
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
    
}

// MARK: - Game Clock Card 2
struct GameClockCard2: View {
    @ObservedObject var gameTimer: GameTimer
    let gameId: UUID
    let isCompleted: Bool
    let onSaveState: () -> Void
    let onEndQuarter: () -> Void
    let onEndGame: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("activeGameId") private var activeGameId: String = ""
    
    var body: some View {
        VStack(spacing: 16) {
            if isCompleted {
                // Game completed banner
                HStack {
                    Image(systemName: "flag.checkered")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Game Completed")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.green)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.green.opacity(0.15))
                )
            } else {
                // Time display row
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Game Time")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        Text(gameTimer.formattedGameTime)
                            .font(.system(size: 28, weight: .bold, design: .monospaced))
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Quarter")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 4) {
                            Text("Q\(gameTimer.currentQuarter)")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(.blue)
                            Text("/ \(gameTimer.quarters)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Quarter time remaining
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Quarter Time")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        Text(gameTimer.formattedQuarterTime)
                            .font(.system(size: 14, weight: .semibold, design: .monospaced))
                            .foregroundColor(.blue)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Remaining")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        Text(gameTimer.timeRemainingInQuarter)
                            .font(.system(size: 14, weight: .semibold, design: .monospaced))
                            .foregroundColor(.orange)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.white.opacity(0.7))
                )
                
                // Control buttons
                HStack(spacing: 12) {
                    if !gameTimer.isGameActive {
                        GameControlButton(
                            title: "Start Game",
                            icon: "play.fill",
                            color: .green
                        ) {
                            activeGameId = gameId.uuidString
                            gameTimer.startGame()
                            PlayerTimeService.shared.ensureActiveStintsFromDefaults(gameId: gameId)
                            onSaveState()
                        }
                    } else {
                        if gameTimer.isRunning {
                            GameControlButton(
                                title: "Pause",
                                icon: "pause.fill",
                                color: .orange
                            ) {
                                gameTimer.pauseClock()
                                onSaveState()
                            }
                        } else {
                            GameControlButton(
                                title: "Resume",
                                icon: "play.fill",
                                color: .green
                            ) {
                                activeGameId = gameId.uuidString
                                gameTimer.startClock()
                                PlayerTimeService.shared.ensureActiveStintsFromDefaults(gameId: gameId)
                            }
                        }
                        
                        GameControlButton(
                            title: "Reset",
                            icon: "arrow.counterclockwise",
                            color: .purple,
                            isCompact: true
                        ) {
                            gameTimer.resetQuarterTimer()
                            onSaveState()
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                        }
                        
                        if gameTimer.currentQuarter > 1 {
                            GameControlButton(
                                title: "Prev Q",
                                icon: "backward.end.fill",
                                color: .gray,
                                isCompact: true
                            ) {
                                gameTimer.previousQuarter()
                                onSaveState()
                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                generator.impactOccurred()
                            }
                        }
                        
                        if gameTimer.currentQuarter < gameTimer.quarters {
                            GameControlButton(
                                title: "End Q\(gameTimer.currentQuarter)",
                                icon: "forward.end.fill",
                                color: .blue,
                                isCompact: true
                            ) {
                                let previousQuarter = gameTimer.currentQuarter
                                gameTimer.endQuarter()
                                PlayerTimeService.shared.moveToQuarter(
                                    gameTimer.currentQuarter,
                                    gameId: gameId,
                                    previousQuarter: previousQuarter
                                )
                                onEndQuarter()
                                onSaveState()
                            }
                        }
                    }
                }
                
                // Prominent End Game button after final quarter time is up
                if gameTimer.isGameActive && gameTimer.currentQuarter == gameTimer.quarters && gameTimer.quarterElapsedTime >= TimeInterval(gameTimer.quarterDurationInSeconds) {
                    Button {
                        onEndGame()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "flag.checkered")
                                .font(.system(size: 18, weight: .bold))
                            Text("End Game")
                                .font(.system(size: 17, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [.green, .green.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.top, 8)
                }
            }
        }
        .padding(16)
        .background(
            GameDetailCardSurface(accent: .green)
        )
    }
}

// MARK: - Score Card 2
struct ScoreCard2: View {
    let myTeamName: String
    let opponentName: String
    let myTeamScore: Int
    let opponentScore: Int
    let isCompleted: Bool
    let onReset: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var resultText: String {
        if myTeamScore > opponentScore {
            return "WIN"
        } else if myTeamScore < opponentScore {
            return "LOSS"
        } else {
            return "DRAW"
        }
    }
    
    private var resultColor: Color {
        if myTeamScore > opponentScore {
            return .green
        } else if myTeamScore < opponentScore {
            return .red
        } else {
            return .orange
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Final result banner for completed games
            if isCompleted {
                HStack(spacing: 8) {
                    Image(systemName: "flag.checkered")
                        .font(.system(size: 11, weight: .semibold))
                    Text("Final Score • \(resultText)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                }
                .foregroundColor(resultColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    resultColor.opacity(0.1)
                )
            }
            
            HStack(spacing: 0) {
                // My team
                VStack(spacing: 6) {
                    Text(myTeamName.prefix(12).uppercased())
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(.red.opacity(0.8))
                        .lineLimit(1)
                    
                    Text("\(myTeamScore)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.red)
                        .contentTransition(.numericText())
                    
                    if isCompleted && myTeamScore > opponentScore {
                        HStack(spacing: 3) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 10))
                            Text("WINNER")
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(.yellow)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(Color.yellow.opacity(0.15))
                        )
                    }
                }
                .frame(maxWidth: .infinity)
                
                // Center divider with VS or lock
                VStack(spacing: 6) {
                    if isCompleted {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [resultColor.opacity(0.2), resultColor.opacity(0.1)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: "lock.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(resultColor.opacity(0.6))
                        }
                    } else {
                        Text("VS")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .foregroundColor(.secondary.opacity(0.5))
                        
                        Button(action: {
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                            onReset()
                        }) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.secondary)
                                .padding(10)
                                .background(
                                    Circle()
                                        .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.white.opacity(0.8))
                                )
                        }
                    }
                }
                .frame(width: 60)
                
                // Opponent
                VStack(spacing: 6) {
                    Text(opponentName.prefix(12).uppercased())
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(.blue.opacity(0.8))
                        .lineLimit(1)
                    
                    Text("\(opponentScore)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)
                        .contentTransition(.numericText())
                    
                    if isCompleted && opponentScore > myTeamScore {
                        HStack(spacing: 3) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 10))
                            Text("WINNER")
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(.yellow)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(Color.yellow.opacity(0.15))
                        )
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 16)
        }
        .background(
            GameDetailCardSurface(accent: isCompleted ? resultColor : .blue)
        )
    }
}

// MARK: - Game Control Button
struct GameControlButton: View {
    let title: String
    let icon: String
    let color: Color
    var isCompact: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            action()
        }) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                if !isCompact {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                }
            }
            .foregroundColor(.white)
            .padding(.horizontal, isCompact ? 12 : 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(color)
            )
        }
    }
}

// MARK: - Analytics Stat Card
struct AnalyticsStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            GameDetailCardSurface(accent: color, cornerRadius: 12)
        )
    }
}

// MARK: - Infraction Breakdown Card
struct InfractionBreakdownCard: View {
    let events: [GameEvent]
    
    private var infractionEvents: [GameEvent] {
        events.filter { $0.eventType == .infraction }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Infraction Breakdown")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(.secondary)
            
            if infractionEvents.isEmpty {
                Text("No infractions recorded")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                let topInfractions = Dictionary(grouping: infractionEvents, by: { $0.infractionType ?? .minor })
                    .mapValues { $0.count }
                    .sorted { $0.value > $1.value }
                    .prefix(3)
                
                ForEach(topInfractions, id: \.key) { infraction, count in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 6, height: 6)
                        
                        Text(infraction.rawValue)
                            .font(.system(size: 13, weight: .medium))
                        
                        Spacer()
                        
                        Text("\(count)")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.orange)
                        
                        GeometryReader { geo in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.orange.opacity(0.3))
                                .frame(width: geo.size.width)
                                .overlay(
                                    HStack {
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(Color.orange)
                                            .frame(width: geo.size.width * CGFloat(count) / CGFloat(infractionEvents.count))
                                        Spacer(minLength: 0)
                                    }
                                )
                        }
                        .frame(width: 60, height: 4)
                    }
                }
            }
        }
    }
}

// MARK: - Circle Entry Analysis Card
struct CircleEntryAnalysisCard: View {
    let events: [GameEvent]
    
    private var circleEvents: [GameEvent] {
        events.filter { $0.eventType == .circleEntry }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Circle Entry Outcomes")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(.secondary)
            
            if circleEvents.isEmpty {
                Text("No circle entries recorded")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                let outcomes = Dictionary(grouping: circleEvents, by: { $0.circleResult ?? .nothing })
                    .mapValues { $0.count }
                
                ForEach(CircleResult.allCases.filter { outcomes[$0] != nil }, id: \.self) { result in
                    if let count = outcomes[result] {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 6, height: 6)
                            
                            Text(result.rawValue)
                                .font(.system(size: 13, weight: .medium))
                            
                            Spacer()
                            
                            Text("\(count)")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(.green)
                            
                            GeometryReader { geo in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.green.opacity(0.3))
                                    .frame(width: geo.size.width)
                                    .overlay(
                                        HStack {
                                            RoundedRectangle(cornerRadius: 2)
                                                .fill(Color.green)
                                                .frame(width: geo.size.width * CGFloat(count) / CGFloat(circleEvents.count))
                                            Spacer(minLength: 0)
                                        }
                                    )
                            }
                            .frame(width: 60, height: 4)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Event Marker View
struct EventMarkerView: View {
    let event: GameEvent
    let circleResultSettings: CircleResultSettings
    let isHighlighted: Bool
    let isFaded: Bool
    
    @AppStorage(TeamColorSettings.ourTeamColorKey) private var ourTeamColorHex = TeamColorSettings.defaultOurTeamHex
    @AppStorage(TeamColorSettings.opponentTeamColorKey) private var opponentTeamColorHex = TeamColorSettings.defaultOpponentHex
    
    init(event: GameEvent, circleResultSettings: CircleResultSettings = CircleResultSettings.loadFromDefaults(), isHighlighted: Bool = false, isFaded: Bool = false) {
        self.event = event
        self.circleResultSettings = circleResultSettings
        self.isHighlighted = isHighlighted
        self.isFaded = isFaded
    }
    
    private var teamColor: Color {
        TeamColorSettings.color(for: event.team, ourHex: ourTeamColorHex, opponentHex: opponentTeamColorHex)
    }
    
    private var color: Color {
        // For circle entries, use the outcome-based color
        if event.eventType == .circleEntry, let result = event.circleResult {
            return circleResultSettings.appearance(for: result).color
        }
        // Default team-based color for other events
        return teamColor
    }
    
    private var icon: String {
        switch event.eventType {
        case .infraction: 
            return "exclamationmark.triangle.fill"
        case .circleEntry:
            if circleResultSettings.showSymbolsOnPitch, let result = event.circleResult {
                return circleResultSettings.appearance(for: result).symbol
            }
            return "circle.fill"
        case .turnover:
            return "arrow.triangle.2.circlepath"
        case .goal: 
            return "soccerball"
        }
    }
    
    private var accessibilityLabel: String {
        var label = "\(event.team.rawValue) \(event.eventType.rawValue)"
        if event.eventType == .circleEntry, let result = event.circleResult {
            label += ", outcome: \(result.rawValue)"
        }
        return label
    }
    
    private var sizeMultiplier: CGFloat {
        CGFloat(circleResultSettings.eventMarkerSize)
    }
    
    var body: some View {
        ZStack {
            // Inner circle with outcome color
            Circle()
                .fill(color)
                .frame(width: 24 * sizeMultiplier, height: 24 * sizeMultiplier)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 10 * sizeMultiplier, weight: .bold))
                        .foregroundColor(.white)
                )
        }
        .opacity(isFaded ? 0.25 : 1.0)
        .scaleEffect(isHighlighted ? 1.2 : 1.0)
        .position(event.location)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }
}

// MARK: - Event Card View
struct EventCardView: View {
    let event: GameEvent
    let players: [Player]
    var isHighlighted: Bool = false
    var isFaded: Bool = false
    var onDelete: (() -> Void)? = nil
    
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage(TeamColorSettings.ourTeamColorKey) private var ourTeamColorHex = TeamColorSettings.defaultOurTeamHex
    @AppStorage(TeamColorSettings.opponentTeamColorKey) private var opponentTeamColorHex = TeamColorSettings.defaultOpponentHex
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()

    private var eventTimeText: String {
        if let gameClockTime = event.gameClockTime {
            return gameClockTime.formattedDuration
        }
        return dateFormatter.string(from: event.timestamp)
    }
    
    private var playerName: String {
        if let playerId = event.playerId,
           let player = players.first(where: { $0.id == playerId }) {
            return player.name.split(separator: " ").last.map(String.init) ?? player.name
        }
        return ""
    }
    
    private var playerNumber: Int? {
        if let playerId = event.playerId,
           let player = players.first(where: { $0.id == playerId }) {
            return player.number
        }
        return nil
    }
    
    private var teamColor: Color {
        TeamColorSettings.color(for: event.team, ourHex: ourTeamColorHex, opponentHex: opponentTeamColorHex)
    }
    
    private var eventIcon: String {
        switch event.eventType {
        case .infraction: return "exclamationmark.triangle.fill"
        case .circleEntry: return "circle.dashed"
        case .turnover: return "arrow.triangle.2.circlepath"
        case .goal: return "soccerball"
        }
    }
    
    private var eventColor: Color {
        switch event.eventType {
        case .infraction: return .orange
        case .circleEntry: return .green
        case .turnover: return .red
        case .goal: return .purple
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header with event type and quarter badge
            HStack(alignment: .top) {
                // Event type icon
                ZStack {
                    Circle()
                        .fill(eventColor.opacity(0.15))
                        .frame(width: 32, height: 32)
                    Image(systemName: eventIcon)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(eventColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(event.eventType.rawValue)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text(eventTimeText)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Quarter badge
                Text("Q\(event.quarter)")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .cyan],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
            }
            
            // Team indicator
            HStack(spacing: 6) {
                Circle()
                    .fill(teamColor)
                    .frame(width: 6, height: 6)
                Text(event.team == .ourTeam ? "Our Team" : "Opponent")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(teamColor)
            }
            
            // Event details
            VStack(alignment: .leading, spacing: 4) {
                if let infraction = event.infractionType {
                    HStack(spacing: 4) {
                        Text(infraction.rawValue)
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(.orange)
                } else if let result = event.circleResult, result != .nothing {
                    HStack(spacing: 4) {
                        Text(result.rawValue)
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(.green)
                } else if event.eventType == .goal {
                    HStack(spacing: 4) {
                        Text("Goal Scored!")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(.purple)
                } else {
                    // Placeholder to maintain consistent height
                    Text(" ")
                        .font(.system(size: 11, weight: .semibold))
                }
                
                // Always show player row with consistent height
                HStack(spacing: 4) {
                    if let playerNumber = playerNumber {
                        Image(systemName: "person.fill")
                            .font(.system(size: 9))
                        Text("#\(playerNumber)")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                        if !playerName.isEmpty {
                            Text(playerName)
                                .font(.system(size: 11, weight: .medium))
                        }
                    } else {
                        Text("Team event")
                            .font(.system(size: 11, weight: .medium))
                    }
                }
                .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .frame(width: 175, height: isHighlighted ? 166 : 140)
        .overlay(alignment: .bottom) {
            if isHighlighted, let onDelete = onDelete {
                Button(role: .destructive, action: onDelete) {
                    HStack(spacing: 4) {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 10, weight: .bold))
                        Text("Delete")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.red)
                    )
                    .padding(.horizontal, 12)
                    .padding(.bottom, 10)
                }
                .buttonStyle(.plain)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: isHighlighted)
        .background(
            GameDetailCardSurface(accent: teamColor, cornerRadius: 14)
        )
        .opacity(isFaded ? 0.4 : 1.0)
        .scaleEffect(isHighlighted ? 1.05 : 1.0)
    }
}

// MARK: - Event List Row View
struct EventListRowView: View {
    let event: GameEvent
    let players: [Player]
    var isHighlighted: Bool = false
    var isFaded: Bool = false
    var onDelete: (() -> Void)? = nil
    
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage(TeamColorSettings.ourTeamColorKey) private var ourTeamColorHex = TeamColorSettings.defaultOurTeamHex
    @AppStorage(TeamColorSettings.opponentTeamColorKey) private var opponentTeamColorHex = TeamColorSettings.defaultOpponentHex
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()

    private var eventTimeText: String {
        if let gameClockTime = event.gameClockTime {
            return gameClockTime.formattedDuration
        }
        return dateFormatter.string(from: event.timestamp)
    }
    
    private var playerName: String {
        if let playerId = event.playerId,
           let player = players.first(where: { $0.id == playerId }) {
            return player.name.split(separator: " ").last.map(String.init) ?? player.name
        }
        return ""
    }
    
    private var playerNumber: Int? {
        if let playerId = event.playerId,
           let player = players.first(where: { $0.id == playerId }) {
            return player.number
        }
        return nil
    }
    
    private var teamColor: Color {
        TeamColorSettings.color(for: event.team, ourHex: ourTeamColorHex, opponentHex: opponentTeamColorHex)
    }
    
    private var eventIcon: String {
        switch event.eventType {
        case .infraction: return "exclamationmark.triangle.fill"
        case .circleEntry: return "circle.dashed"
        case .turnover: return "arrow.triangle.2.circlepath"
        case .goal: return "soccerball"
        }
    }
    
    private var eventColor: Color {
        switch event.eventType {
        case .infraction: return .orange
        case .circleEntry: return .green
        case .turnover: return .red
        case .goal: return .purple
        }
    }
    
    private var eventDetail: String {
        if let infraction = event.infractionType {
            return infraction.rawValue
        } else if let result = event.circleResult, result != .nothing {
            return result.rawValue
        } else if event.eventType == .goal, let goalType = event.goalType {
            return goalType.rawValue
        } else if event.eventType == .turnover {
            return "Lost possession"
        }
        return ""
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Event type icon
            ZStack {
                Circle()
                    .fill(eventColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: eventIcon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(eventColor)
            }
            
            // Event info
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(event.eventType.rawValue)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    if !eventDetail.isEmpty {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text(eventDetail)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(eventColor)
                    }
                }
                
                HStack(spacing: 6) {
                    // Team indicator
                    Circle()
                        .fill(teamColor)
                        .frame(width: 6, height: 6)
                    Text(event.team == .ourTeam ? "Our Team" : "Opponent")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    if let playerNumber = playerNumber {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text("#\(playerNumber)")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.secondary)
                        if !playerName.isEmpty {
                            Text(playerName)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            Spacer()
            
            // Time, quarter, and (when highlighted) delete button
            HStack(spacing: 8) {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(eventTimeText)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondary)
                    Text("Q\(event.quarter)")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [.blue, .cyan],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                }
                
                if isHighlighted, let onDelete = onDelete {
                    Button(role: .destructive, action: onDelete) {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(Color.red))
                    }
                    .buttonStyle(.plain)
                    .transition(.scale(scale: 0.6).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.75), value: isHighlighted)
        }
        .padding(10)
        .background(
            GameDetailCardSurface(accent: teamColor, cornerRadius: 10)
        )
        .opacity(isFaded ? 0.4 : 1.0)
        .scaleEffect(isHighlighted ? 1.02 : 1.0)
    }
}

// MARK: - Marker Move Controls
struct MarkerMoveControls: View {
    let position: CGPoint
    let pitchSize: CGSize
    
    private let arrowSize: CGFloat = 22
    private let arrowPad: CGFloat = 36
    
    var body: some View {
        ZStack {
            // Subtle backdrop
            Circle()
                .fill(Color.black.opacity(0.08))
                .frame(width: arrowPad * 2 + arrowSize, height: arrowPad * 2 + arrowSize)
                .position(position)
            
            // Up
            arrowIcon(angle: 0)
                .position(x: position.x, y: max(position.y - arrowPad, arrowSize / 2))
            
            // Down
            arrowIcon(angle: 180)
                .position(x: position.x, y: min(position.y + arrowPad, pitchSize.height - arrowSize / 2))
            
            // Left
            arrowIcon(angle: -90)
                .position(x: max(position.x - arrowPad, arrowSize / 2), y: position.y)
            
            // Right
            arrowIcon(angle: 90)
                .position(x: min(position.x + arrowPad, pitchSize.width - arrowSize / 2), y: position.y)
        }
        .allowsHitTesting(false)
        .transition(.opacity.combined(with: .scale(scale: 0.85)))
    }
    
    private func arrowIcon(angle: Double) -> some View {
        Image(systemName: "triangle.fill")
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(.white.opacity(0.95))
            .rotationEffect(.degrees(angle))
            .frame(width: arrowSize, height: arrowSize)
    }
}

// MARK: - Heatmap Overlay
struct HeatmapOverlay: View {
    let events: [GameEvent]
    let pitchSize: CGSize
    
    @AppStorage(TeamColorSettings.ourTeamColorKey) private var ourTeamColorHex = TeamColorSettings.defaultOurTeamHex
    @AppStorage(TeamColorSettings.opponentTeamColorKey) private var opponentTeamColorHex = TeamColorSettings.defaultOpponentHex
    
    private func teamColor(for team: TeamType) -> Color {
        TeamColorSettings.color(for: team, ourHex: ourTeamColorHex, opponentHex: opponentTeamColorHex)
    }
    
    var body: some View {
        ZStack {
            ForEach(events) { event in
                Circle()
                    .fill(teamColor(for: event.team).opacity(0.3))
                    .frame(width: 50, height: 50)
                    .blur(radius: 15)
                    .position(event.location)
            }
        }
    }
}

// MARK: - Quarter Pill
struct QuarterPill: View {
    let title: String
    let subtitle: String
    let count: Int
    let isSelected: Bool
    let gradientColors: [Color]
    let isDisabled: Bool
    let isLive: Bool
    let action: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: {
            if !isDisabled {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                action()
            }
        }) {
            VStack(spacing: 6) {
                // Main content
                VStack(spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                    
                    Text(subtitle)
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .textCase(.uppercase)
                        .opacity(0.8)
                }
                
                // Event count badge
                HStack(spacing: 3) {
                    if isLive && !isSelected {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 5, height: 5)
                    }
                    Text("\(count)")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.white.opacity(0.25) : Color(.systemGray5))
                )
            }
            .foregroundColor(isSelected ? .white : (isDisabled ? .secondary.opacity(0.4) : .primary))
            .frame(width: 58, height: 72)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        isSelected
                            ? LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(colors: [Color(.systemGray6), Color(.systemGray6)], startPoint: .top, endPoint: .bottom)
                    )
            )
        }
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.5 : 1.0)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Quick Stat Badge
struct QuickStatBadge: View {
    let icon: String
    let value: Int
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(color)
                Text("\(value)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct GameDetailCardSurface: View {
    let accent: Color
    var cornerRadius: CGFloat = 16

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(.ultraThinMaterial)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.04) : Color.white.opacity(0.6))
            )
    }
}

#Preview {
    NavigationStack {
        GameDetailView(game: Game(myTeamName: "Eagles", opponentName: "Tigers", location: "Home Field"))
    }
    .modelContainer(for: [Game.self, Team.self, Player.self], inMemory: true)
}
