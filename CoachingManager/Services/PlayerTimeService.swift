//
//  PlayerTimeService.swift
//  CoachingManager
//
//  Created by Taylor Santos on 02/03/2026.
//

import Foundation
import SwiftUI
import Combine

/// A singleton service that tracks player play times using wall-clock time.
/// Tracking is completely independent of the view hierarchy — switching tabs,
/// navigating away, or backgrounding the app does not interrupt accumulation.
class PlayerTimeService: ObservableObject {
    static let shared = PlayerTimeService()

    // MARK: - Published State

    /// Player times per game and quarter: [GameID: [Quarter: [PlayerID: TimeInterval]]]
    @Published private(set) var playerTimes: [UUID: [Int: [UUID: TimeInterval]]] = [:]

    /// Players currently on pitch per game: [GameID: Set<PlayerID>]
    @Published var playersOnPitch: [UUID: Set<UUID>] = [:]

    /// Tick counter — UI observers read this to force redraws each second.
    @Published private(set) var tickCount: Int = 0

    /// Callback set by PitchView to trigger a SwiftData save every 30 s.
    var onSaveRequested: (() -> Void)?

    // MARK: - Private State

    private var displayTimer: Timer?
    private var lastSaveTime: Date = Date()
    private var trackedGames: [UUID: Game] = [:]

    /// Wall-clock date at which we started crediting time for a given game.
    /// Reset whenever the game timer pauses or the roster changes.
    private var trackingStartDate: [UUID: Date] = [:]

    /// Accumulated seconds already banked before the current tracking window started.
    /// When the timer pauses we bank elapsed time here and clear trackingStartDate.
    private var bankedSeconds: [UUID: [Int: [UUID: TimeInterval]]] = [:]

    // MARK: - Init

    private init() {
        startDisplayTimer()
    }

    // MARK: - Display Timer (UI refresh, ~1 Hz)

    private func startDisplayTimer() {
        displayTimer?.invalidate()
        let t = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(t, forMode: .common)
        displayTimer = t
    }

    private func tick() {
        // Always refresh the pitch roster from UserDefaults so we keep tracking
        // even when PitchView is not on screen.
        refreshPlayersOnPitchFromDefaults()

        var didUpdate = false

        for (gameId, playerIds) in playersOnPitch {
            guard !playerIds.isEmpty else { continue }

            guard let gameTimer = resolveGameTimer(for: gameId) else { continue }

            let quarter = gameTimer.currentQuarter

            if gameTimer.isRunning {
                // Ensure a tracking window is open for this game.
                if trackingStartDate[gameId] == nil {
                    trackingStartDate[gameId] = Date()
                }
                didUpdate = true
            } else {
                // Timer paused — bank any in-progress window and close it.
                bankCurrentWindow(gameId: gameId, playerIds: playerIds, quarter: quarter)
            }
        }

        if didUpdate {
            DispatchQueue.main.async {
                self.tickCount += 1
                self.objectWillChange.send()

                if Date().timeIntervalSince(self.lastSaveTime) >= 30 {
                    self.lastSaveTime = Date()
                    self.onSaveRequested?()
                }
            }
        }
    }

    // MARK: - Wall-Clock Accumulation

    /// Seconds elapsed in the currently open tracking window for a game.
    private func liveWindowSeconds(for gameId: UUID) -> TimeInterval {
        guard let start = trackingStartDate[gameId] else { return 0 }
        return Date().timeIntervalSince(start)
    }

    /// Banks elapsed time from the open window into `bankedSeconds`, then closes the window.
    private func bankCurrentWindow(gameId: UUID, playerIds: Set<UUID>, quarter: Int) {
        guard let start = trackingStartDate[gameId] else { return }
        let elapsed = Date().timeIntervalSince(start)
        guard elapsed > 0 else { return }

        for playerId in playerIds {
            let existing = bankedSeconds[gameId]?[quarter]?[playerId] ?? 0
            setBanked(existing + elapsed, playerId: playerId, gameId: gameId, quarter: quarter)
        }
        trackingStartDate[gameId] = nil
    }

    private func setBanked(_ value: TimeInterval, playerId: UUID, gameId: UUID, quarter: Int) {
        if bankedSeconds[gameId] == nil { bankedSeconds[gameId] = [:] }
        if bankedSeconds[gameId]?[quarter] == nil { bankedSeconds[gameId]?[quarter] = [:] }
        bankedSeconds[gameId]?[quarter]?[playerId] = value
    }

    // MARK: - Time Access

    /// Live play time for a player, including any open tracking window.
    func getTime(for playerId: UUID, gameId: UUID, quarter: Int) -> TimeInterval {
        let banked = bankedSeconds[gameId]?[quarter]?[playerId] ?? 0
        let isRunning = resolveGameTimer(for: gameId)?.isRunning ?? false
        let live: TimeInterval = isRunning ? liveWindowSeconds(for: gameId) : 0
        return banked + live
    }

    func getAllTimes(for gameId: UUID, quarter: Int) -> [UUID: TimeInterval] {
        let isRunning = resolveGameTimer(for: gameId)?.isRunning ?? false
        let live: TimeInterval = isRunning ? liveWindowSeconds(for: gameId) : 0

        var result = bankedSeconds[gameId]?[quarter] ?? [:]

        // Add the live window to all players currently on the pitch.
        if let playerIds = playersOnPitch[gameId] {
            for playerId in playerIds {
                result[playerId] = (result[playerId] ?? 0) + live
            }
        }
        return result
    }

    /// Directly set a player's banked time (used when loading from persisted storage).
    func setTime(_ time: TimeInterval, for playerId: UUID, gameId: UUID, quarter: Int) {
        setBanked(time, playerId: playerId, gameId: gameId, quarter: quarter)
        objectWillChange.send()
    }

    // MARK: - Pitch Management

    func addPlayerToPitch(_ playerId: UUID, gameId: UUID) {
        if playersOnPitch[gameId] == nil { playersOnPitch[gameId] = [] }
        playersOnPitch[gameId]?.insert(playerId)
    }

    func removePlayerFromPitch(_ playerId: UUID, gameId: UUID) {
        // Bank the current window before removing so time is not lost.
        if let gameTimer = resolveGameTimer(for: gameId),
           let ids = playersOnPitch[gameId], !ids.isEmpty {
            bankCurrentWindow(gameId: gameId, playerIds: ids, quarter: gameTimer.currentQuarter)
        }
        playersOnPitch[gameId]?.remove(playerId)
        // Re-open a window immediately for remaining players.
        if let gameTimer = resolveGameTimer(for: gameId),
           gameTimer.isRunning,
           !(playersOnPitch[gameId]?.isEmpty ?? true) {
            trackingStartDate[gameId] = Date()
        }
    }

    func setPlayersOnPitch(_ playerIds: [UUID], gameId: UUID) {
        // Bank the current window before the roster changes.
        if let gameTimer = resolveGameTimer(for: gameId),
           let ids = playersOnPitch[gameId], !ids.isEmpty {
            bankCurrentWindow(gameId: gameId, playerIds: ids, quarter: gameTimer.currentQuarter)
        }
        playersOnPitch[gameId] = Set(playerIds)
        // Re-open a fresh window for the new roster if the timer is running.
        if let gameTimer = resolveGameTimer(for: gameId),
           gameTimer.isRunning, !playerIds.isEmpty {
            trackingStartDate[gameId] = Date()
        }
    }

    func clearPitch(for gameId: UUID) {
        if let gameTimer = resolveGameTimer(for: gameId),
           let ids = playersOnPitch[gameId], !ids.isEmpty {
            bankCurrentWindow(gameId: gameId, playerIds: ids, quarter: gameTimer.currentQuarter)
        }
        playersOnPitch[gameId] = []
        trackingStartDate[gameId] = nil
    }

    // MARK: - Game Tracking

    func track(game: Game) {
        trackedGames[game.id] = game
    }

    // MARK: - UserDefaults Sync

    private func refreshPlayersOnPitchFromDefaults() {
        let activeGameIdString = UserDefaults.standard.string(forKey: "activeGameId") ?? ""
        guard let activeGameId = UUID(uuidString: activeGameIdString) else { return }

        guard let data = UserDefaults.standard.data(forKey: "pitchPlayers"),
              let savedPlayers = try? JSONDecoder().decode([SavedPitchPlayer].self, from: data)
        else { return }

        let playerIds = Set(savedPlayers.map { $0.playerId })
        guard playersOnPitch[activeGameId] != playerIds else { return }

        // Roster changed — bank the current window first.
        if let gameTimer = resolveGameTimer(for: activeGameId),
           let ids = playersOnPitch[activeGameId], !ids.isEmpty {
            bankCurrentWindow(gameId: activeGameId, playerIds: ids, quarter: gameTimer.currentQuarter)
        }
        playersOnPitch[activeGameId] = playerIds
        // Re-open the window immediately if the timer is running.
        if let gameTimer = resolveGameTimer(for: activeGameId),
           gameTimer.isRunning, !playerIds.isEmpty {
            trackingStartDate[activeGameId] = Date()
        }
    }

    // MARK: - Reset & Load

    func resetTimes(for gameId: UUID, quarter: Int) {
        bankedSeconds[gameId]?[quarter] = [:]
        // Close any open window — a fresh start means old window is invalid.
        trackingStartDate[gameId] = nil
        // Re-open immediately if the timer is running.
        if let gameTimer = resolveGameTimer(for: gameId), gameTimer.isRunning,
           !(playersOnPitch[gameId]?.isEmpty ?? true) {
            trackingStartDate[gameId] = Date()
        }
    }

    func resetAllTimes(for gameId: UUID) {
        bankedSeconds[gameId] = [:]
        trackingStartDate[gameId] = nil
        if let gameTimer = resolveGameTimer(for: gameId), gameTimer.isRunning,
           !(playersOnPitch[gameId]?.isEmpty ?? true) {
            trackingStartDate[gameId] = Date()
        }
    }

    func loadTimes(from game: Game) {
        let gameId = game.id
        bankedSeconds[gameId] = [:]

        for (playerIdString, quarterTimes) in game.playerPlayTimes {
            guard let playerId = UUID(uuidString: playerIdString) else { continue }
            for (quarterString, time) in quarterTimes {
                guard let quarter = Int(quarterString) else { continue }
                setBanked(time, playerId: playerId, gameId: gameId, quarter: quarter)
            }
        }
    }

    // MARK: - Background Time Sync

    /// Called when returning from background. The caller (PitchView) has already
    /// computed how many wall-clock seconds elapsed while backgrounded. We close
    /// the stale tracking window (which started before the background event and
    /// would otherwise double-count that time), credit the caller-computed
    /// seconds directly, then reopen a fresh window from now.
    func addBackgroundTime(_ seconds: TimeInterval, gameId: UUID, quarter: Int) {
        // Close the stale window without banking its wall-clock elapsed time
        // (that time is already covered by the `seconds` parameter).
        trackingStartDate[gameId] = nil

        guard let playerIds = playersOnPitch[gameId] else { return }
        for playerId in playerIds {
            let existing = bankedSeconds[gameId]?[quarter]?[playerId] ?? 0
            setBanked(existing + seconds, playerId: playerId, gameId: gameId, quarter: quarter)
        }

        // Re-open a fresh window from now.
        if let gameTimer = resolveGameTimer(for: gameId), gameTimer.isRunning {
            trackingStartDate[gameId] = Date()
        }
    }

    // MARK: - Helpers

    private func resolveGameTimer(for gameId: UUID) -> GameTimer? {
        if let existing = GameTimerService.shared.activeTimers[gameId] {
            return existing
        }
        if let game = trackedGames[gameId] {
            return GameTimerService.shared.timer(for: game)
        }
        return nil
    }

    deinit {
        displayTimer?.invalidate()
    }
}
