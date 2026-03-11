//
//  PitchView.swift
//  CoachingManager
//
//  Created by Taylor Santos on 06/01/2026.
//
//
struct PlayerTimeMinimalView: View {
    let players: [Player]
    let pitchPlayers: [PitchPlayer]
    let playerQuarterTimes: [UUID: TimeInterval]
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header summary card
                summaryCard
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 20)
                
                // Player list
                LazyVStack(spacing: 0) {
                    ForEach(Array(sortedPlayers.enumerated()), id: \.element.id) { index, player in
                        playerRow(for: player, index: index)
                    }
                }
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 40)
        }
        .background(Color(.systemGray6).opacity(0.5))
        .navigationTitle("Play Time")
        .navigationBarTitleDisplayMode(.large)
    }
    
    private var summaryCard: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(pitchPlayers.count)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.green)
                Text("On Pitch")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            Divider()
                .frame(height: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(players.count - pitchPlayers.count)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.orange)
                Text("On Bench")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(players.count)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.blue)
                Text("Total")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 8, x: 0, y: 4)
        )
    }
    
    private var sortedPlayers: [Player] {
        players.sorted { $0.number < $1.number }
    }
    
    private func playerRow(for player: Player, index: Int) -> some View {
        let time = getTime(for: player)
        let isOnPitch = pitchPlayers.contains { $0.player.id == player.id }
        
        return HStack(spacing: 12) {
            // Status indicator
            Circle()
                .fill(isOnPitch ? Color.green : Color.orange.opacity(0.5))
                .frame(width: 8, height: 8)
            
            // Player number
            Text("#\(player.number)")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 36, alignment: .leading)
            
            // Player name
            Text(player.name)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.primary)
            
            Spacer()
            
            // Time played
            HStack(spacing: 4) {
                if isOnPitch {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.green)
                }
                Text(formatTime(time))
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundColor(isOnPitch ? .primary : .secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            index % 2 == 0
                ? Color(.systemBackground)
                : Color(.systemGray6).opacity(0.5)
        )
    }
    
    private func getTime(for player: Player) -> TimeInterval {
        playerQuarterTimes[player.id] ?? 0
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}


import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct PitchView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Query(sort: \Team.name) private var teams: [Team]
    @Query(sort: \Player.number) private var players: [Player]
    @Query(filter: #Predicate<Game> { !$0.isCompleted }, sort: \Game.date, order: .reverse) private var activeGames: [Game]
    
    @State private var pitchPlayers: [PitchPlayer] = []
    @AppStorage("defaultTeamId") private var defaultTeamId: String = ""
    @AppStorage("activeGameId") private var activeGameId: String = ""
    
    // Game settings for quarter duration
    @State private var gameSettings = GameSettings()
    
    // Current active game (if any)
    private var currentGame: Game? {
        guard !activeGameId.isEmpty else { return activeGames.first }
        return activeGames.first { $0.id.uuidString == activeGameId } ?? activeGames.first
    }
    
    private var selectedTeam: Team? {
        guard !defaultTeamId.isEmpty else { return nil }
        return teams.first { $0.id.uuidString == defaultTeamId }
    }
    

    
    // Store the active quarter duration in seconds (updated from game timer)
    @State private var activeQuarterDuration: TimeInterval = 900
    
    // Quarter duration in seconds - use stored value that's kept in sync with game timer
    private var quarterDurationSeconds: TimeInterval {
        activeQuarterDuration
    }
    
    // Drop zone visual feedback states
    @State private var isDropTargeted = false
    @State private var dropLocation: CGPoint? = nil
    
    @AppStorage("minPlayersOnPitch") private var minPlayersOnPitch = 11
    @AppStorage("enableSkillFilter") private var enableSkillFilter = false
    @AppStorage("requiredSkills") private var requiredSkills: String = ""
    
    @State private var showNotification = false
    @State private var showSkillNotification = false
    @State private var showPlayerCountNotification = false
    @State private var playerCountNotificationMessage: String = ""
    @State private var missingSkills: [String] = []
    @State private var showClearConfirmation = false
    
    // Swap player state
    @State private var selectedPitchPlayerForSwap: PitchPlayer? = nil
    
    // Shared player time service (continues running when navigating away)
    @ObservedObject private var playerTimeService = PlayerTimeService.shared
    
    // Game timer for syncing with match view
    @State private var gameTimer: GameTimer? = nil
    
    // Track scene phase for background handling
    @Environment(\.scenePhase) private var scenePhase
    @State private var backgroundTimestamp: Date? = nil
    @State private var previousGameId: String = ""
    
    // Device detection - true for iPhone, false for iPad
    private var isCompact: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }
    
    // Left panel width based on device
    private var leftPanelWidth: CGFloat {
        isCompact ? 90 : 140
    }
    
    // Responsive sizing - maximized pitch
    private var pitchWidth: CGFloat {
        let panelAndPadding = isCompact ? 130 : 200 // Account for left panel + padding
        return (UIScreen.main.bounds.width) - CGFloat(panelAndPadding)
    }
    private var pitchHeight: CGFloat {
        (UIScreen.main.bounds.height) * (isCompact ? 0.72 : 0.78)
    }
    
    // Computed property to get player times from the shared service
    private var playerQuarterTimes: [UUID: TimeInterval] {
        guard let game = currentGame else { return [:] }
        let timer = GameTimerService.shared.timer(for: game)
        return playerTimeService.getAllTimes(for: game.id, quarter: timer.currentQuarter)
    }
    
    // Calculate quarter play percentage for a player
    // Service tickCount ensures this recalculates when timer updates
    private func quarterPlayPercentage(for player: Player) -> Double {
        _ = playerTimeService.tickCount // Force recalculation on service tick
        guard quarterDurationSeconds > 0 else { return 0 }
        let time = playerQuarterTimes[player.id] ?? 0
        return min(time / quarterDurationSeconds, 1.0)
    }
    
    private var requiredSkillsSet: Set<String> {
        if let data = requiredSkills.data(using: .utf8),
           let skills = try? JSONDecoder().decode([String].self, from: data) {
            return Set(skills)
        }
        return []
    }
    
    // Filter players by selected team
    private var filteredPlayers: [Player] {
        if let selectedTeam = selectedTeam {
            return selectedTeam.players
        }
        return players
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: - Header Stats Bar
//                headerStatsBar
//                    .padding(.horizontal, 20)
//                    .padding(.top, 8)
                
                // MARK: - Timer Display (above pitch)
                if let timer = gameTimer, let game = currentGame, !game.isCompleted {
                    HStack {
                        Spacer()
                        PitchTimerOverlay(gameTimer: timer, game: game)
                        Spacer()
                    }
                    .padding(.horizontal, isCompact ? 12 : 20)
                    .padding(.top, isCompact ? 4 : 8)
                }
                
                // MARK: - Main Content
                HStack(alignment: .top, spacing: isCompact ? 8 : 16) {
                    // MARK: Left Panel - Team & Squad
                    leftPanel
                        .frame(width: leftPanelWidth)
                        
                    Spacer()
                    
                    // MARK: Pitch Area
                    pitchArea
                }
                .padding(.horizontal, isCompact ? 12 : 20)
                .padding(.top, isCompact ? 4 : 8)
                
                Spacer()
            }
            
            // MARK: - Floating Notifications
            notificationsOverlay
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Pitch Planner")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    // Clear all button
                    if !pitchPlayers.isEmpty {
                        Button {
                            showClearConfirmation = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 14, weight: .medium))
                                Text("Clear")
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .foregroundColor(.red.opacity(0.8))
                        }
                    }
                    
                    // Play time tracker
                    NavigationLink(destination: PlayerTimeMinimalView(
                        players: players,
                        pitchPlayers: pitchPlayers,
                        playerQuarterTimes: playerQuarterTimes
                    )) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .confirmationDialog(
            "Clear Formation",
            isPresented: $showClearConfirmation,
            titleVisibility: .visible
        ) {
            Button("Clear All Players", role: .destructive) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    pitchPlayers.removeAll()
                }
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove all \(pitchPlayers.count) players from the pitch.")
        }
        .sheet(item: $selectedPitchPlayerForSwap) { pitchPlayer in
            SwapPlayerSheet(
                currentPlayer: pitchPlayer.player,
                availablePlayers: filteredPlayers.filter { p in
                    !pitchPlayers.contains { $0.player.id == p.id }
                },
                // quarterPlayPercentage: quarterPlayPercentage,
                onSwap: { newPlayer in
                    swapPlayer(pitchPlayer: pitchPlayer, with: newPlayer)
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .onAppear {
            selectedPitchPlayerForSwap = nil // Clear any stale state
            loadSavedPositions()
            loadQuarterTimes()
            loadGameSettings()
            syncPlayersOnPitchWithService()
            // Initialize game timer for sync with match view
            if let game = currentGame {
                gameTimer = GameTimerService.shared.timer(for: game)
            }
            // Track initial game ID
            previousGameId = activeGameId
            // Set up auto-save callback
            playerTimeService.onSaveRequested = { [modelContext, activeGameId, activeGames] in
                // Find and save to the current game
                guard !activeGameId.isEmpty else { return }
                if let game = activeGames.first(where: { $0.id.uuidString == activeGameId }) ?? activeGames.first {
                    let timer = GameTimerService.shared.timer(for: game)
                    let quarter = timer.currentQuarter
                    let times = PlayerTimeService.shared.getAllTimes(for: game.id, quarter: quarter)
                    for (playerId, time) in times {
                        game.updatePlayTime(forPlayer: playerId, quarter: quarter, time: time)
                    }
                    try? modelContext.save()
                }
            }
        }
        .onDisappear {
            savePositions()
            saveQuarterTimes()
            saveTimesToGame()
        }
        .onChange(of: pitchPlayers) { _, newPlayers in
            validateSkills()
            syncPlayersOnPitchWithService()
        }
        .onChange(of: activeGames) { _, newGames in
            // Sync activeQuarterDuration when games list changes
            if let game = newGames.first(where: { $0.id.uuidString == activeGameId }) ?? newGames.first {
                let timer = GameTimerService.shared.timer(for: game)
                activeQuarterDuration = TimeInterval(timer.quarterDurationInSeconds)
                gameTimer = timer
            }
        }
        .onChange(of: activeGameId) { oldId, newId in
            // When game changes, reset player quarter times
            if !oldId.isEmpty && oldId != newId {
                // Save times for the old game before resetting
                saveTimesToGame()
                // Reset player quarter times for the new game via service
                if let oldGameUUID = UUID(uuidString: oldId) {
                    playerTimeService.clearPitch(for: oldGameUUID)
                }
                // Load times for the new game (if any exist)
                loadQuarterTimes()
                syncPlayersOnPitchWithService()
            }
            previousGameId = newId
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            handleScenePhaseChange(from: oldPhase, to: newPhase)
        }
    }
    
    // MARK: - Sync Players on Pitch with Service
    private func syncPlayersOnPitchWithService() {
        guard let game = currentGame else { return }
        let playerIds = pitchPlayers.map { $0.player.id }
        playerTimeService.setPlayersOnPitch(playerIds, gameId: game.id)
        
        // Update quarter duration
        let timer = GameTimerService.shared.timer(for: game)
        activeQuarterDuration = TimeInterval(timer.quarterDurationInSeconds)
    }
    
    // MARK: - Scene Phase Handling
    private func handleScenePhaseChange(from oldPhase: ScenePhase, to newPhase: ScenePhase) {
        switch newPhase {
        case .background, .inactive:
            // App going to background - save timestamp if game timer is running
            if let game = currentGame {
                let timer = GameTimerService.shared.timer(for: game)
                if timer.isRunning {
                    backgroundTimestamp = Date()
                }
            }
            // Save current state
            saveQuarterTimes()
            saveTimesToGame()
            
        case .active:
            // App coming to foreground - calculate elapsed time and add to players
            if let timestamp = backgroundTimestamp,
               let game = currentGame {
                let timer = GameTimerService.shared.timer(for: game)
                
                // Only add time if the game timer is still running
                if timer.isRunning {
                    let elapsedSeconds = Date().timeIntervalSince(timestamp)
                    
                    // Add elapsed time via the service
                    playerTimeService.addBackgroundTime(elapsedSeconds, gameId: game.id, quarter: timer.currentQuarter)
                }
            }
            backgroundTimestamp = nil
            
            // Re-sync players on pitch
            syncPlayersOnPitchWithService()
            
        @unknown default:
            break
        }
    }
    
    // MARK: Save Times to Game
    private func saveTimesToGame() {
        guard let game = currentGame else { return }
        let timer = GameTimerService.shared.timer(for: game)
        let quarter = timer.currentQuarter
        
        // Update each player's time for the current quarter
        for (playerId, time) in playerQuarterTimes {
            game.updatePlayTime(forPlayer: playerId, quarter: quarter, time: time)
        }
        
        try? modelContext.save()
    }
    
    // MARK: New Quarter - Reset Times (called from GameDetailView when quarter ends)
    static func resetQuarterTimes() {
        UserDefaults.standard.removeObject(forKey: "playerQuarterTimes")
    }
    
    // Reset times for a specific game/quarter
    static func resetQuarterTimes(for gameId: UUID) {
        UserDefaults.standard.removeObject(forKey: "playerQuarterTimes")
        // Also reset in the service
        if let timer = GameTimerService.shared.activeTimers[gameId] {
            PlayerTimeService.shared.resetTimes(for: gameId, quarter: timer.currentQuarter)
        }
    }
    
    private func saveQuarterTimes() {
        // Save to game directly since service holds the data
        saveTimesToGame()
    }
    
    private func loadQuarterTimes() {
        guard let game = currentGame else { return }
        let timer = GameTimerService.shared.timer(for: game)
        let quarter = timer.currentQuarter
        let gameTimes = game.playerPlayTimes
        
        // If game is newly started (elapsedTime is near 0), start with fresh times
        if timer.elapsedTime < 5 && timer.isGameActive && timer.currentQuarter == 1 {
            playerTimeService.resetTimes(for: game.id, quarter: quarter)
            return
        }
        
        // Load times from game into the service
        for (playerIdString, quarterTimes) in gameTimes {
            if let playerId = UUID(uuidString: playerIdString),
               let time = quarterTimes["\(quarter)"] {
                playerTimeService.setTime(time, for: playerId, gameId: game.id, quarter: quarter)
            }
        }
    }
    
    // MARK: Load Game Settings
    private func loadGameSettings() {
        if let settingsString = UserDefaults.standard.string(forKey: "gameSettingsData"),
           let data = settingsString.data(using: .utf8),
           let settings = try? JSONDecoder().decode(GameSettings.self, from: data) {
            gameSettings = settings
        }
        
        // Sync activeQuarterDuration from current game (priority) or settings
        if let game = currentGame {
            let gameTimer = GameTimerService.shared.timer(for: game)
            activeQuarterDuration = TimeInterval(gameTimer.quarterDurationInSeconds)
        } else {
            activeQuarterDuration = TimeInterval(gameSettings.quarterDurationInSeconds)
        }
    }
    
    // MARK: Skill Validation
    private func validateSkills() {
        // Reset notifications
        withAnimation {
            showPlayerCountNotification = false
            missingSkills.removeAll()
        }
        
        // Check 1: Minimum players on pitch
        if pitchPlayers.count < minPlayersOnPitch {
            let missingCount = minPlayersOnPitch - pitchPlayers.count
            playerCountNotificationMessage = "Need \(missingCount) more player\(missingCount == 1 ? "" : "s")"
            withAnimation {
                showPlayerCountNotification = true
            }
        }
        
        // Check 2: Required skills (only if filter is enabled)
        guard enableSkillFilter else { return }
        
        let skillsOnPitch = pitchPlayers.flatMap { $0.player.skills }
        let newMissingSkills = requiredSkillsSet.filter { !skillsOnPitch.contains($0) }
        
        withAnimation {
            missingSkills = Array(newMissingSkills).sorted()
        }
    }
    
    // MARK: Persistence
    private func savePositions() {
        let saved = pitchPlayers.map {
            SavedPitchPlayer(
                id: $0.id,
                playerId: $0.player.id,
                x: $0.position.x,
                y: $0.position.y,
                timeOnPitch: $0.timeOnPitch
            )
        }
        if let data = try? JSONEncoder().encode(saved) {
            UserDefaults.standard.set(data, forKey: "pitchPlayers")
        }
    }
    
    private func loadSavedPositions() {
        guard let data = UserDefaults.standard.data(forKey: "pitchPlayers") else { return }
        do {
            let savedPlayers = try JSONDecoder().decode([SavedPitchPlayer].self, from: data)
            pitchPlayers = savedPlayers.compactMap { saved -> PitchPlayer? in
                if let player = players.first(where: { $0.id == saved.playerId }) {
                    return PitchPlayer(
                        id: saved.id,
                        player: player,
                        position: CGPoint(x: saved.x, y: saved.y),
                        timeOnPitch: saved.timeOnPitch
                    )
                } else {
                    return nil
                }
            }
        } catch {
            print("Failed to load positions: \(error)")
        }
    }
    
    private func removePlayerFromPitch(_ player: Player) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            pitchPlayers.removeAll { $0.player.id == player.id }
        }
    }
    
    private func swapPlayer(pitchPlayer: PitchPlayer, with newPlayer: Player) {
        // Find the index of the current player
        guard let index = pitchPlayers.firstIndex(where: { $0.id == pitchPlayer.id }) else { return }
        
        // Create new pitch player at same position
        let newPitchPlayer = PitchPlayer(
            id: UUID(),
            player: newPlayer,
            position: pitchPlayer.position,
            timeOnPitch: 0
        )
        
        // Perform the swap with animation
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            pitchPlayers[index] = newPitchPlayer
        }
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Clear selection
        selectedPitchPlayerForSwap = nil
    }
}

// MARK: - View Components Extension
extension PitchView {
    
    // MARK: Background
    private var backgroundGradient: some View {
        LinearGradient(
            colors: colorScheme == .dark
                ? [Color(.systemBackground), Color(.systemGray6)]
                : [Color(.systemGray6).opacity(0.5), Color(.systemBackground)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    // MARK: Header Stats Bar
    private var headerStatsBar: some View {
        HStack(spacing: 12) {
            // On Pitch stat
            StatCard(
                icon: "sportscourt.fill",
                value: "\(pitchPlayers.count)",
                label: "On Pitch",
                color: pitchPlayers.count >= minPlayersOnPitch ? .green : .orange
            )
            
            // Available stat
            StatCard(
                icon: "person.3.fill",
                value: "\(filteredPlayers.filter { p in !pitchPlayers.contains { $0.player.id == p.id } }.count)",
                label: "Available",
                color: .blue
            )
            
            // Required stat
            StatCard(
                icon: "target",
                value: "\(minPlayersOnPitch)",
                label: "Required",
                color: .purple
            )
            
            Spacer()
            
            // Show current team name
            if let team = selectedTeam {
                HStack(spacing: 6) {
                    Image(systemName: "flag.fill")
                        .font(.system(size: 12))
                    Text(team.name)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                }
                .foregroundColor(.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
                )
                .overlay(
                    Capsule()
                        .stroke(Color(.systemGray4), lineWidth: 0.5)
                )
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: Left Panel
    private var leftPanel: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "person.3.sequence.fill")
                    .font(.system(size: isCompact ? 10 : 14))
                Text("Squad")
                    .font(.system(size: isCompact ? 10 : 15, weight: .semibold, design: .rounded))
                Spacer()

            }
            .padding(.horizontal, isCompact ? 8 : 14)
            .padding(.top, isCompact ? 8 : 14)
            .padding(.bottom, isCompact ? 6 : 10)
            
            // Clear Pitch Button (moved up)
            if !pitchPlayers.isEmpty {
                Button {
                    showClearConfirmation = true
                } label: {
                    HStack(spacing: isCompact ? 4 : 6) {
                        Image(systemName: "arrow.uturn.left.circle.fill")
                            .font(.system(size: isCompact ? 10 : 12, weight: .semibold))
                        Text(isCompact ? "Clear" : "Clear Pitch")
                            .font(.system(size: isCompact ? 10 : 12, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, isCompact ? 8 : 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.red)
                    )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, isCompact ? 6 : 10)
                .padding(.bottom, isCompact ? 6 : 10)
            }
            
            // Divider with gradient
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, Color(.systemGray4), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
                .padding(.horizontal, 12)
            
            // Players list
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: isCompact ? 6 : 10) {
                    let availablePlayers = filteredPlayers.filter { p in
                        !pitchPlayers.contains { $0.player.id == p.id }
                    }
                    
                    if availablePlayers.isEmpty {
                        emptySquadView
                    } else {
                        ForEach(availablePlayers) { player in
                            DraggablePlayerView(
                                player: player,
                                quarterPlayPercentage: quarterPlayPercentage(for: player),
                                playTime: playerQuarterTimes[player.id] ?? 0,
                                isCompact: isCompact
                            )
                                .transition(.asymmetric(
                                    insertion: .scale(scale: 0.8).combined(with: .opacity),
                                    removal: .scale(scale: 0.8).combined(with: .opacity)
                                ))
                        }
                    }
                }
                .padding(.top, isCompact ? 8 : 12)
                .padding(.bottom, isCompact ? 60 : 80)
                .padding(.horizontal, isCompact ? 2 : 4)
                .animation(.spring(response: 0.35, dampingFraction: 0.75), value: pitchPlayers.count)
            }
            
            // Drop hint footer
            if !pitchPlayers.isEmpty {
                VStack(spacing: 4) {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.clear, Color(.systemGray4), .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 1)
                        .padding(.horizontal, 12)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.left.to.line")
                            .font(.system(size: 9))
                        Text("Drag to bench")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(.secondary.opacity(0.6))
                    .padding(.vertical, 8)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
    }
    
    // MARK: Empty Squad View
    private var emptySquadView: some View {
        VStack(spacing: 8) {
            Image(systemName: "person.badge.plus")
                .font(.system(size: 28))
                .foregroundColor(.secondary.opacity(0.4))
            Text("All players\non pitch")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }
    
    // MARK: Pitch Area
    private var pitchArea: some View {
        GeometryReader { geo in
            ZStack {
                // Modern pitch with grass effect
                modernPitchBackground(size: geo.size)
                
                // Pitch markings
                PitchMarkings()
                    .stroke(
                        Color.white.opacity(0.85),
                        style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                    )
                
                // Drop zone indicator
                DropZoneIndicator(
                    isTargeted: isDropTargeted,
                    dropLocation: dropLocation,
                    pitchSize: geo.size
                )
                
                // Players on pitch
                ForEach($pitchPlayers) { $pitchPlayer in
                    PlayerOnPitchView(
                        player: pitchPlayer.player,
                        position: $pitchPlayer.position,
                        pitchSize: geo.size,
                        quarterPlayPercentage: quarterPlayPercentage(for: pitchPlayer.player),
                        playTime: playerQuarterTimes[pitchPlayer.player.id] ?? 0,
                        isCompact: isCompact,
                        onRemove: {
                            removePlayerFromPitch(pitchPlayer.player)
                        },
                        onTap: {
                            selectedPitchPlayerForSwap = pitchPlayer
                        }
                    )
                }
                
                // Empty state hint
                if pitchPlayers.isEmpty {
                    emptyPitchOverlay
                }
            }
            .onDrop(
                of: [UTType.text],
                delegate: PitchDropDelegate(
                    players: players,
                    pitchPlayers: $pitchPlayers,
                    pitchSize: geo.size,
                    isTargeted: $isDropTargeted,
                    dropLocation: $dropLocation
                )
            )
        }
        .frame(width: pitchWidth, height: pitchHeight)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: isDropTargeted
                            ? [.blue.opacity(0.8), .purple.opacity(0.8)]
                            : [Color.white.opacity(0.3), Color.white.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: isDropTargeted ? 3 : 2
                )
        )
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.4 : 0.2), radius: 12, x: 0, y: 6)
        .animation(.easeInOut(duration: 0.2), value: isDropTargeted)
    }
    
    // MARK: Modern Pitch Background
    private func modernPitchBackground(size: CGSize) -> some View {
        ZStack {
            // Solid grass color
            Color(red: 0.18, green: 0.52, blue: 0.22)
            
            // Subtle vignette for depth
            RadialGradient(
                colors: [.clear, Color.black.opacity(0.1)],
                center: .center,
                startRadius: size.width * 0.4,
                endRadius: size.width * 0.9
            )
            
            // Drop target highlight
            if isDropTargeted {
                Color.blue.opacity(0.1)
                    .transition(.opacity)
            }
        }
    }
    
    // MARK: Empty Pitch Overlay
    private var emptyPitchOverlay: some View {
        VStack(spacing: 12) {
            Image(systemName: "arrow.left.and.right")
                .font(.system(size: 36, weight: .light))
                .foregroundColor(.white.opacity(0.5))
            
            Text("Drag players here")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.2))
        )
    }
    
    // MARK: Notifications Overlay
    private var notificationsOverlay: some View {
        VStack(alignment: .trailing, spacing: 10) {
            if showPlayerCountNotification {
                ModernNotificationBadge(
                    message: playerCountNotificationMessage,
                    icon: "person.2.fill",
                    style: .warning
                )
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
            
            ForEach(missingSkills, id: \.self) { skill in
                ModernNotificationBadge(
                    message: "Missing: \(skill)",
                    icon: "exclamationmark.triangle.fill",
                    style: .error
                )
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        .padding(.top, 8)
        .padding(.trailing, 24)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: showPlayerCountNotification)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: missingSkills)
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
        )
    }
}

struct ModernNotificationBadge: View {
    let message: String
    let icon: String
    let style: NotificationStyle
    
    @State private var isExpanded = true
    @State private var collapseTask: Task<Void, Never>? = nil
    
    // Timing constants
    private let initialDisplayDuration: Double = 4.0
    private let reExpandDisplayDuration: Double = 5.0
    
    enum NotificationStyle {
        case warning, error, info
        
        var color: Color {
            switch self {
            case .warning: return .orange
            case .error: return .red
            case .info: return .blue
            }
        }
        
        var backgroundColor: Color {
            switch self {
            case .warning: return Color(.systemBackground)
            case .error: return Color(.systemBackground)
            case .info: return Color(.systemBackground)
            }
        }
    }
    
    var body: some View {
        Group {
            if isExpanded {
                expandedView
            } else {
                collapsedView
            }
        }
        .onAppear {
            scheduleCollapse(after: initialDisplayDuration)
        }
        .onDisappear {
            collapseTask?.cancel()
        }
    }
    
    // MARK: - Expanded View
    private var expandedView: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(style.color)
            
            Text(message)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
                .lineLimit(1)
            
            Spacer(minLength: 6)
            
            // Close button
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded = false
                }
                collapseTask?.cancel()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)
                    .padding(5)
                    .background(Circle().fill(Color(.systemGray5)))
            }
        }
        .frame(width: 220)
        .padding(.leading, 16)
        .padding(.trailing, 10)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(style.backgroundColor)
                .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(style.color, lineWidth: 2)
        )
        .transition(
            .asymmetric(
                insertion: .scale(scale: 0.9).combined(with: .opacity),
                removal: .scale(scale: 0.9).combined(with: .opacity)
            )
        )
    }
    
    // MARK: - Collapsed View (Icon Only)
    private var collapsedView: some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                isExpanded = true
            }
            scheduleCollapse(after: reExpandDisplayDuration)
        } label: {
            ZStack {
                Circle()
                    .fill(Color(.systemBackground))
                    .frame(width: 40, height: 40)
                    .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 3)
                    .overlay(
                        Circle()
                            .stroke(style.color, lineWidth: 2)
                    )
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(style.color)
            }
        }
        .buttonStyle(.plain)
        .transition(
            .asymmetric(
                insertion: .scale(scale: 0.5).combined(with: .opacity),
                removal: .scale(scale: 0.5).combined(with: .opacity)
            )
        )
    }
    
    // MARK: - Collapse Timer
    private func scheduleCollapse(after seconds: Double) {
        collapseTask?.cancel()
        collapseTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            if !Task.isCancelled {
                await MainActor.run {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        isExpanded = false
                    }
                }
            }
        }
    }
}

// MARK: - Swap Player Sheet
struct SwapPlayerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    let currentPlayer: Player
    let availablePlayers: [Player]
    // let quarterPlayPercentage: (Player) -> Double
    let onSwap: (Player) -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Current player being subbed off
                currentPlayerCard
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 12)
                
                // Swap arrow
                HStack {
                    Rectangle()
                        .fill(Color(.systemGray4))
                        .frame(height: 1)
                    
                    Image(systemName: "arrow.up.arrow.down.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.blue)
                    
                    Rectangle()
                        .fill(Color(.systemGray4))
                        .frame(height: 1)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 12)
                
                // Available players list
                if availablePlayers.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(availablePlayers) { player in
                                playerRow(for: player)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Substitute Player")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // Sort by play percentage (lowest first - prioritize players who need more time)
    // private var sortedAvailablePlayers: [Player] {
    //     availablePlayers.sorted { quarterPlayPercentage($0) < quarterPlayPercentage($1) }
    // }
    
    private var currentPlayerCard: some View {
        HStack(spacing: 14) {
            // Player circle
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.red.opacity(0.9), Color.red],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                
                Text("\(currentPlayer.number)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(currentPlayer.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                HStack(spacing: 6) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                    Text("Coming off")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Play time indicator
            // VStack(alignment: .trailing, spacing: 2) {
            //     Text(formatPercentage(quarterPlayPercentage(currentPlayer)))
            //         .font(.system(size: 14, weight: .bold, design: .rounded))
            //         .foregroundColor(progressColor(for: quarterPlayPercentage(currentPlayer)))
            //     Text("play time")
            //         .font(.system(size: 10, weight: .medium))
            //         .foregroundColor(.secondary)
            // }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 6, x: 0, y: 3)
        )
    }
    
    private func playerRow(for player: Player) -> some View {
        Button {
            onSwap(player)
        } label: {
            HStack(spacing: 14) {
                // Player circle
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.green.opacity(0.9), Color.green],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                    
                    Text("\(player.number)")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(player.name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.primary)
                    
                    // Play time progress bar
                    // HStack(spacing: 8) {
                    //     GeometryReader { geo in
                    //         ZStack(alignment: .leading) {
                    //             RoundedRectangle(cornerRadius: 2)
                    //                 .fill(Color(.systemGray4))
                    //                 .frame(height: 4)
                    //             
                    //             RoundedRectangle(cornerRadius: 2)
                    //                 .fill(progressColor(for: quarterPlayPercentage(player)))
                    //                 .frame(width: geo.size.width * CGFloat(min(quarterPlayPercentage(player), 1.0)), height: 4)
                    //         }
                    //     }
                    //     .frame(height: 4)
                    //     .frame(maxWidth: 80)
                    //     
                    //     Text(formatPercentage(quarterPlayPercentage(player)))
                    //         .font(.system(size: 11, weight: .semibold, design: .rounded))
                    //         .foregroundColor(progressColor(for: quarterPlayPercentage(player)))
                    // }
                }
                
                Spacer()
                
                // Swap indicator
                Image(systemName: "arrow.left.arrow.right.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.blue)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray5), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.badge.minus")
                .font(.system(size: 40))
                .foregroundColor(.secondary.opacity(0.5))
            
            Text("No available players")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.secondary)
            
            Text("All players are on the pitch")
                .font(.system(size: 13))
                .foregroundColor(.secondary.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.bottom, 60)
    }
    
    // private func progressColor(for percentage: Double) -> Color {
    //     if percentage >= 0.75 {
    //         return .green
    //     } else if percentage >= 0.5 {
    //         return .yellow
    //     } else if percentage >= 0.25 {
    //         return .orange
    //     } else {
    //         return .red
    //     }
    // }
    // 
    // private func formatPercentage(_ value: Double) -> String {
    //     "\(Int(min(value * 100, 100)))%"
    // }
}

// MARK: - Compact Timer Display for Pitch View
struct PitchTimerOverlay: View {
    @ObservedObject var gameTimer: GameTimer
    let game: Game
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 8) {
            // Running indicator
            Circle()
                .fill(gameTimer.isRunning ? Color.green : Color.orange)
                .frame(width: 8, height: 8)
                .shadow(color: gameTimer.isRunning ? .green.opacity(0.5) : .clear, radius: 4)
            
            // Game time
            VStack(alignment: .leading, spacing: 0) {
                Text(gameTimer.formattedGameTime)
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                
                Text(gameTimer.isRunning ? "Running" : (gameTimer.isGameActive ? "Paused" : "Not Started"))
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            // Divider
            Rectangle()
                .fill(Color.white.opacity(0.3))
                .frame(width: 1, height: 24)
                .padding(.horizontal, 4)
            
            // Quarter info
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 2) {
                    Text("Q\(gameTimer.currentQuarter)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("/\(gameTimer.quarters)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Text(gameTimer.timeRemainingInQuarter)
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(.orange)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.7),
                            Color.black.opacity(0.5)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
        )
    }
}
