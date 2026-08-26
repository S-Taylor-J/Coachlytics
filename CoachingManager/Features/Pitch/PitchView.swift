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
    let playerTimes: [UUID: TimeInterval]
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
                .cardSurface(cornerRadius: 16)
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 40)
        }
        .appBackground()
        .navigationTitle("Play Time")
        .navigationBarTitleDisplayMode(.large)
    }
    
    private var summaryCard: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(pitchPlayers.count)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.success)
                Text("On Pitch")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }

            Divider()
                .frame(height: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text("\(players.count - pitchPlayers.count)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.warning)
                Text("On Bench")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(players.count)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.brandAccent)
                Text("Total")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }
        }
        .padding(20)
        .cardSurface(cornerRadius: 16)
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
                .fill(isOnPitch ? AppTheme.success : AppTheme.warning.opacity(0.5))
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
                        .foregroundColor(AppTheme.success)
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
                ? AppTheme.surfaceFill(colorScheme)
                : AppTheme.secondarySurfaceFill(colorScheme)
        )
    }
    
    private func getTime(for player: Player) -> TimeInterval {
        playerTimes[player.id] ?? 0
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
    
    // Game settings for quarter duration — observed so Settings edits apply immediately
    @ObservedObject private var settingsStore = AppSettingsStore.shared
    private var gameSettings: GameSettings { settingsStore.gameSettings }

    private var playableGames: [Game] {
        activeGames.filter { !$0.isScheduled || $0.isGameActive }
    }

    // Current active game (if any)
    private var currentGame: Game? {
        guard !playableGames.isEmpty else { return nil }
        if !activeGameId.isEmpty, let game = playableGames.first(where: { $0.id.uuidString == activeGameId }) {
            return game
        }
        return playableGames.first
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
     @AppStorage("showPlayerTimers") private var showPlayerTimers = false
//    let showPlayerTimers = false // Temporary toggle for player timers until fully implemented

    @State private var showNotification = false
    @State private var showSkillNotification = false
    @State private var showPlayerCountNotification = false
    @State private var playerCountNotificationMessage: String = ""
    @State private var missingSkills: [String] = []
    @State private var showClearConfirmation = false
    
    // Swap player state
    @State private var selectedPitchPlayerForSwap: PitchPlayer? = nil
    
    // Bench collapse state
    @AppStorage("pitchBenchCollapsed") private var isBenchCollapsed: Bool = false
    
    // Shared player time service (continues running when navigating away)
    @ObservedObject private var playerTimeService = PlayerTimeService.shared
    
    
    // Track scene phase for background handling
    @Environment(\.scenePhase) private var scenePhase
    @State private var previousGameId: String = ""
    
    // Device detection - true for iPhone, false for iPad
    private var isCompact: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }
    
    // Left panel width based on device and collapse state
    private var leftPanelWidth: CGFloat {
        if isBenchCollapsed { return 28 }
        return isCompact ? 78 : 116
    }

    
    // Computed property to get player times from the shared service
    private func playerQuarterTimes(for game: Game, timer: GameTimer) -> [UUID: TimeInterval] {
        playerTimeService.getAllTimes(for: game.id, quarter: timer.currentQuarter)
    }

    private func playerTotalTimes(for game: Game) -> [UUID: TimeInterval] {
        playerTimeService.getAllTimesTotal(for: game.id)
    }
    
    // Calculate quarter play percentage for a player
    // Service tickCount ensures this recalculates when timer updates
    private func quarterPlayPercentage(for player: Player, game: Game, timer: GameTimer) -> Double {
        _ = playerTimeService.tickCount // Force recalculation on service tick
        guard quarterDurationSeconds > 0 else { return 0 }
        let time = playerQuarterTimes(for: game, timer: timer)[player.id] ?? 0
        return min(time / quarterDurationSeconds, 1.0)
    }

    private func configurePlayerTimeAutoSave(for game: Game) {
        playerTimeService.onSaveRequested = { [modelContext] in
            PlayerTimeService.shared.persistStints(to: game)
            try? modelContext.save()
        }
    }
    
    private var requiredSkillsSet: Set<String> {
        if let data = requiredSkills.data(using: .utf8),
           let skills = try? JSONDecoder().decode([String].self, from: data) {
            return Set(skills)
        }
        return []
    }
    
    private var activeGamePlayers: [Player] {
        guard let game = currentGame else { return [] }
        if game.hasSelectedPlayerSelection {
            let selectedIds = Set(game.selectedPlayerIds)
            return players
                .filter { selectedIds.contains($0.id) }
                .sorted { $0.number < $1.number }
        }
        if let teamId = game.myTeamId,
           let team = teams.first(where: { $0.id == teamId }) {
            return team.players.sorted { $0.number < $1.number }
        }
        return players
    }

    private var noGamePlayers: [Player] {
        if let selectedTeam = selectedTeam {
            return selectedTeam.players.sorted { $0.number < $1.number }
        }
        return players
    }

    // Filter players by current game selection or default team
    private var filteredPlayers: [Player] {
        if currentGame != nil {
            return activeGamePlayers
        }
        return noGamePlayers
    }
    
    var body: some View {
        if let game = currentGame {
            PitchTimerObservedView(game: game) { gameTimer, game in
                pitchContent(game: game, gameTimer: gameTimer)
            }
        } else {
            pitchContentNoGame()
        }
    }

    @ViewBuilder
    private func pitchContent(game: Game, gameTimer: GameTimer) -> some View {
        let _ = playerTimeService.tickCount
        let _ = gameTimer.elapsedTime
        let playerTimes = playerTotalTimes(for: game)
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
                if !game.isCompleted {
                    HStack {
                        Spacer()
                        PitchTimerOverlay(gameTimer: gameTimer, game: game)
                        Spacer()
                    }
                    .padding(.horizontal, isCompact ? 12 : 20)
                    .padding(.top, isCompact ? 4 : 8)
                }
                
                // MARK: - Main Content
                VStack(spacing: isCompact ? 10 : 16) {
                    pitchArea(game: game, gameTimer: gameTimer, playerTimes: playerTimes)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    bottomBenchPanel(game: game, gameTimer: gameTimer, playerTimes: playerTimes)
                        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isBenchCollapsed)
                }
                .frame(maxHeight: .infinity, alignment: .top)
                .padding(.horizontal, isCompact ? 12 : 20)
                .padding(.top, isCompact ? 4 : 8)
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
                        players: filteredPlayers,
                        pitchPlayers: pitchPlayers,
                        playerTimes: playerTotalTimes(for: game)
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
            prunePitchPlayersToAvailable()
            loadQuarterTimes()
            loadGameSettings()
            syncPlayersOnPitchWithService()
            prunePitchPlayersToAvailable()
            if gameTimer.isRunning {
                playerTimeService.ensureActiveStints(
                    gameId: game.id,
                    playerIds: pitchPlayers.map { $0.player.id }
                )
            }
            if activeGameId != game.id.uuidString {
                activeGameId = game.id.uuidString
            }
            // Track initial game ID
            previousGameId = activeGameId
            configurePlayerTimeAutoSave(for: game)
            activeQuarterDuration = TimeInterval(gameTimer.quarterDurationInSeconds)
        }
        .onDisappear {
            savePositions()
            saveQuarterTimes()
            saveTimesToGame()
        }
        .onChange(of: pitchPlayers) { _, newPlayers in
            validateSkills()
            syncPlayersOnPitchWithService()
            savePositions()
        }
        .onChange(of: activeGames) { _, newGames in
            // Sync activeQuarterDuration when games list changes
            let eligibleGames = newGames.filter { !$0.isScheduled || $0.isGameActive }
            if let updatedGame = eligibleGames.first(where: { $0.id.uuidString == activeGameId }) ?? eligibleGames.first {
                if activeGameId != updatedGame.id.uuidString {
                    activeGameId = updatedGame.id.uuidString
                }
                let timer = GameTimerService.shared.timer(for: updatedGame)
                activeQuarterDuration = TimeInterval(timer.quarterDurationInSeconds)
                configurePlayerTimeAutoSave(for: updatedGame)
            }
        }
        .onChange(of: activeGameId) { oldId, newId in
            // When game changes, reset player quarter times
            if !oldId.isEmpty && oldId != newId {
                // Save times for the old game before resetting
                if let oldGame = activeGames.first(where: { $0.id.uuidString == oldId }) {
                    saveTimesToGame(for: oldGame)
                }
                // Reset player quarter times for the new game via service
                if let oldGameUUID = UUID(uuidString: oldId) {
                    playerTimeService.clearPitch(for: oldGameUUID)
                }
                // Load times for the new game (if any exist)
                loadQuarterTimes()
                syncPlayersOnPitchWithService()
                prunePitchPlayersToAvailable()
            }
            previousGameId = newId
            if let updatedGame = currentGame {
                configurePlayerTimeAutoSave(for: updatedGame)
            }
        }
        .onChange(of: gameTimer.isRunning) { _, isRunning in
            guard isRunning else { return }
            playerTimeService.ensureActiveStints(
                gameId: game.id,
                playerIds: pitchPlayers.map { $0.player.id }
            )
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            handleScenePhaseChange(from: oldPhase, to: newPhase)
        }
    }

    @ViewBuilder
    private func pitchContentNoGame() -> some View {
        ZStack {
            // Background gradient
            backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Status banner
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 8, height: 8)
                    Text("No active game")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)

                // MARK: - Main Content
                VStack(spacing: isCompact ? 10 : 16) {
                    pitchAreaNoGame()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    bottomBenchPanelNoGame()
                        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isBenchCollapsed)
                }
                .frame(maxHeight: .infinity, alignment: .top)
                .padding(.horizontal, isCompact ? 12 : 20)
                .padding(.top, isCompact ? 4 : 8)
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

                    // Play time tracker (disabled without a game)
                    NavigationLink(destination: PlayerTimeMinimalView(
                        players: filteredPlayers,
                        pitchPlayers: pitchPlayers,
                        playerTimes: [:]
                    )) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.blue)
                    }
                    .disabled(true)
                    .opacity(0.4)
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
            prunePitchPlayersToAvailable()
            loadGameSettings()
        }
        .onDisappear {
            savePositions()
        }
        .onChange(of: pitchPlayers) { _, newPlayers in
            validateSkills()
            savePositions()
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            handleScenePhaseChange(from: oldPhase, to: newPhase)
        }
    }
    
    // MARK: - Sync Players on Pitch with Service
    private func syncPlayersOnPitchWithService() {
        guard let game = currentGame else { return }
        playerTimeService.track(game: game)
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
            saveTimesToGame()
            
        case .active:
            saveTimesToGame()
            
        @unknown default:
            break
        }
    }
    
    // MARK: Save Times to Game
    private func saveTimesToGame() {
        guard let game = currentGame else { return }
        saveTimesToGame(for: game)
    }

    private func saveTimesToGame(for game: Game) {
        playerTimeService.persistStints(to: game)
        try? modelContext.save()
    }
    
    // MARK: New Quarter - Reset Times (called from GameDetailView when quarter ends)
    static func resetQuarterTimes() {
        return
    }
    
    // Reset times for a specific game/quarter
    static func resetQuarterTimes(for gameId: UUID) {
        _ = gameId
    }
    
    private func saveQuarterTimes() {
        // Save to game directly since service holds the data
        saveTimesToGame()
    }
    
    private func loadQuarterTimes() {
        guard let game = currentGame else { return }
        let timer = GameTimerService.shared.timer(for: game)
        
        // If game is newly started (elapsedTime is near 0), start with fresh times
        if timer.elapsedTime < 5 && timer.isGameActive && timer.currentQuarter == 1 {
            playerTimeService.resetStints(for: game.id)
            playerTimeService.persistStints(to: game)
            try? modelContext.save()
            return
        }

        // Load stints from game into the service
        playerTimeService.loadStints(from: game)
    }
    
    // MARK: Load Game Settings
    private func loadGameSettings() {
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
                timeOnPitch: 0
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
            let availablePlayers = filteredPlayers
            pitchPlayers = savedPlayers.compactMap { saved -> PitchPlayer? in
                if let player = availablePlayers.first(where: { $0.id == saved.playerId }) {
                    return PitchPlayer(
                        id: saved.id,
                        player: player,
                        position: CGPoint(x: saved.x, y: saved.y),
                        timeOnPitch: 0
                    )
                } else {
                    return nil
                }
            }
        } catch {
            print("Failed to load positions: \(error)")
        }
    }

    private func prunePitchPlayersToAvailable() {
        let availableIds = Set(filteredPlayers.map { $0.id })
        if pitchPlayers.contains(where: { !availableIds.contains($0.player.id) }) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                pitchPlayers.removeAll { !availableIds.contains($0.player.id) }
            }
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

private struct PitchTimerObservedView<Content: View>: View {
    @ObservedObject var gameTimer: GameTimer
    let game: Game
    let content: (GameTimer, Game) -> Content

    init(game: Game, @ViewBuilder content: @escaping (GameTimer, Game) -> Content) {
        self.game = game
        self._gameTimer = ObservedObject(wrappedValue: GameTimerService.shared.timer(for: game))
        self.content = content
    }

    var body: some View {
        content(gameTimer, game)
    }
}

// MARK: - View Components Extension
extension PitchView {
    
    // MARK: Background
    private var backgroundGradient: some View {
        AppBackgroundView()
    }
    
    // MARK: Header Stats Bar
    private var headerStatsBar: some View {
        HStack(spacing: 12) {
            // On Pitch stat
            StatCard(
                icon: "sportscourt.fill",
                value: "\(pitchPlayers.count)",
                label: "On Pitch",
                color: pitchPlayers.count >= minPlayersOnPitch ? AppTheme.success : AppTheme.warning
            )

            // Available stat
            StatCard(
                icon: "person.3.fill",
                value: "\(filteredPlayers.filter { p in !pitchPlayers.contains { $0.player.id == p.id } }.count)",
                label: "Available",
                color: AppTheme.brandAccent
            )

            // Required stat
            StatCard(
                icon: "target",
                value: "\(minPlayersOnPitch)",
                label: "Required",
                color: AppTheme.purpleAccent
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
                .cardSurface(cornerRadius: 100)
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: Left Panel
    private var benchCount: Int {
        filteredPlayers.filter { p in
            !pitchPlayers.contains { $0.player.id == p.id }
        }.count
    }

    private func bottomBenchPanel(game: Game, gameTimer: GameTimer, playerTimes: [UUID: TimeInterval]) -> some View {
        Group {
            if isBenchCollapsed {
                collapsedBenchBar
            } else {
                expandedBenchPanel(game: game, gameTimer: gameTimer, playerTimes: playerTimes)
            }
        }
    }

    private func bottomBenchPanelNoGame() -> some View {
        Group {
            if isBenchCollapsed {
                collapsedBenchBar
            } else {
                expandedBenchPanelNoGame()
            }
        }
    }

    private var collapsedBenchBar: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    isBenchCollapsed = false
                }
            } label: {
                Image(systemName: "chevron.up")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
                    .padding(8)
                    .background(Circle().fill(AppTheme.secondarySurfaceFill(colorScheme)))
            }
            .buttonStyle(.plain)

            Text("Bench")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(.secondary)

            if benchCount > 0 {
                Text("\(benchCount)")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(AppTheme.brandAccent))
            }

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .cardSurface(cornerRadius: 16)
    }
    
    private var collapsedBenchTab: some View {
        VStack(spacing: 8) {
            // Expand chevron button
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    isBenchCollapsed = false
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.plain)
            
            Divider()
                .padding(.horizontal, 4)
            
            // Rotated "Bench" label + player count badge
            VStack(spacing: 6) {
                let benchCount = filteredPlayers.filter { p in
                    !pitchPlayers.contains { $0.player.id == p.id }
                }.count
                
                if benchCount > 0 {
                    ZStack {
                        Circle()
                            .fill(AppTheme.brandAccent)
                            .frame(width: 20, height: 20)
                        Text("\(benchCount)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                    }
                }

                Text("Bench")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundColor(.secondary)
                    .rotationEffect(.degrees(-90))
                    .fixedSize()
                    .frame(width: 20, height: 60)
            }
            .padding(.top, 4)

            Spacer()
        }
        .frame(maxHeight: .infinity)
        .cardSurface(cornerRadius: 16)
    }
    
    private func expandedBenchPanel(game: Game, gameTimer: GameTimer, playerTimes: [UUID: TimeInterval]) -> some View {
        VStack(spacing: 0) {
            // Header with collapse button
            HStack {
                Image(systemName: "person.3.sequence.fill")
                    .font(.system(size: isCompact ? 10 : 14))
                Text("")
                    .font(.system(size: isCompact ? 10 : 15, weight: .semibold, design: .rounded))
                Spacer()
                // Collapse button
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        isBenchCollapsed = true
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                        .padding(6)
                        .background(Circle().fill(AppTheme.secondarySurfaceFill(colorScheme)))
                }
                .buttonStyle(.plain)
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
                            .fill(AppTheme.danger)
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
                        colors: [.clear, AppTheme.strokeColor(colorScheme), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
                .padding(.horizontal, 12)

            // Players list
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: isCompact ? 8 : 12) {
                    let availablePlayers = filteredPlayers.filter { p in
                        !pitchPlayers.contains { $0.player.id == p.id }
                    }

                    if availablePlayers.isEmpty {
                        emptySquadView
                            .frame(width: 140)
                    } else {
                        ForEach(availablePlayers) { player in
                            DraggablePlayerView(
                                player: player,
                                quarterPlayPercentage: quarterPlayPercentage(for: player, game: game, timer: gameTimer),
                                playTime: playerTimes[player.id] ?? 0,
                                isCompact: isCompact,
                                showTimer: showPlayerTimers
                            )
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0.8).combined(with: .opacity),
                                removal: .scale(scale: 0.8).combined(with: .opacity)
                            ))
                        }
                    }
                }
                .padding(.horizontal, isCompact ? 10 : 14)
                .padding(.vertical, isCompact ? 8 : 12)
                .animation(.spring(response: 0.35, dampingFraction: 0.75), value: pitchPlayers.count)
            }

        }
        .cardSurface(cornerRadius: 16)
    }

    private func expandedBenchPanelNoGame() -> some View {
        VStack(spacing: 0) {
            // Header with collapse button
            HStack {
                Image(systemName: "person.3.sequence.fill")
                    .font(.system(size: isCompact ? 10 : 14))
                Text("")
                    .font(.system(size: isCompact ? 10 : 15, weight: .semibold, design: .rounded))
                Spacer()
                // Collapse button
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        isBenchCollapsed = true
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                        .padding(6)
                        .background(Circle().fill(AppTheme.secondarySurfaceFill(colorScheme)))
                }
                .buttonStyle(.plain)
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
                            .fill(AppTheme.danger)
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
                        colors: [.clear, AppTheme.strokeColor(colorScheme), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
                .padding(.horizontal, 12)

            // Players list
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: isCompact ? 8 : 12) {
                    let availablePlayers = filteredPlayers.filter { p in
                        !pitchPlayers.contains { $0.player.id == p.id }
                    }

                    if availablePlayers.isEmpty {
                        emptySquadView
                            .frame(width: 140)
                    } else {
                        ForEach(availablePlayers) { player in
                            DraggablePlayerView(
                                player: player,
                                quarterPlayPercentage: 0,
                                playTime: 0,
                                isCompact: isCompact,
                                showTimer: showPlayerTimers
                            )
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0.8).combined(with: .opacity),
                                removal: .scale(scale: 0.8).combined(with: .opacity)
                            ))
                        }
                    }
                }
                .padding(.horizontal, isCompact ? 10 : 14)
                .padding(.vertical, isCompact ? 8 : 12)
                .animation(.spring(response: 0.35, dampingFraction: 0.75), value: pitchPlayers.count)
            }

        }
        .cardSurface(cornerRadius: 16)
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
    private func pitchArea(game: Game, gameTimer: GameTimer, playerTimes: [UUID: TimeInterval]) -> some View {
        GeometryReader { geo in
            ZStack {
                PitchBackgroundImageView(isDropTargeted: isDropTargeted, imageContentMode: .fill)
                
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
                        quarterPlayPercentage: quarterPlayPercentage(for: pitchPlayer.player, game: game, timer: gameTimer),
                        playTime: playerTimes[pitchPlayer.player.id] ?? 0,
                        isCompact: isCompact,
                        showTimer: showPlayerTimers,
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
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
         .aspectRatio(1024/1536, contentMode: .fit)
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

    private func pitchAreaNoGame() -> some View {
        GeometryReader { geo in
            ZStack {
                PitchBackgroundImageView(isDropTargeted: isDropTargeted, imageContentMode: .fill)

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
                        quarterPlayPercentage: 0,
                        playTime: 0,
                        isCompact: isCompact,
                        showTimer: showPlayerTimers,
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
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .aspectRatio(1024/1536, contentMode: .fit)
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
        .cardSurface(cornerRadius: 10, showShadow: false)
    }
}

struct ModernNotificationBadge: View {
    let message: String
    let icon: String
    let style: NotificationStyle
    @Environment(\.colorScheme) private var colorScheme

    @State private var isExpanded = true
    @State private var collapseTask: Task<Void, Never>? = nil
    
    // Timing constants
    private let initialDisplayDuration: Double = 4.0
    private let reExpandDisplayDuration: Double = 5.0
    
    enum NotificationStyle {
        case warning, error, info
        
        var color: Color {
            switch self {
            case .warning: return AppTheme.warning
            case .error: return AppTheme.danger
            case .info: return AppTheme.brandAccent
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
                    .background(Circle().fill(AppTheme.secondarySurfaceFill(colorScheme)))
            }
        }
        .frame(width: 220)
        .padding(.leading, 16)
        .padding(.trailing, 10)
        .padding(.vertical, 12)
        .cardSurface(cornerRadius: 12, strokeAccent: style.color)
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
                    .fill(AppTheme.surfaceFill(colorScheme))
                    .frame(width: 40, height: 40)
                    .shadow(color: AppTheme.shadowColor(colorScheme), radius: 6, x: 0, y: 3)
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
                        .fill(AppTheme.strokeColor(colorScheme))
                        .frame(height: 1)

                    Image(systemName: "arrow.up.arrow.down.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(AppTheme.brandAccent)

                    Rectangle()
                        .fill(AppTheme.strokeColor(colorScheme))
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
            .appBackground()
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
                            colors: [AppTheme.danger.opacity(0.9), AppTheme.danger],
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
                        .foregroundColor(AppTheme.danger)
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
        .cardSurface(cornerRadius: 14)
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
                                colors: [AppTheme.success.opacity(0.9), AppTheme.success],
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
                    .foregroundColor(AppTheme.brandAccent)
            }
            .padding(14)
            .cardSurface(cornerRadius: 12, showShadow: false)
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
                .fill(gameTimer.isRunning ? AppTheme.success : AppTheme.warning)
                .frame(width: 8, height: 8)
                .shadow(color: gameTimer.isRunning ? AppTheme.success.opacity(0.5) : .clear, radius: 4)
            
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

