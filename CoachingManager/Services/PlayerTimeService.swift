//
//  PlayerTimeService.swift
//  CoachingManager
//
//  Created by Taylor Santos on 02/03/2026.
//

import Foundation
import SwiftUI
import Combine

/// A singleton service that tracks player play times as stints based on the match timer.
/// Stints are anchored to the game timer's elapsed time, so the game clock is the source of truth.
class PlayerTimeService: ObservableObject {
    static let shared = PlayerTimeService()

    // MARK: - Published State

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

    /// Player stints per game: [GameID: [PlayerID: [PlayerStint]]]
    private var playerStintsByGame: [UUID: [UUID: [PlayerStint]]] = [:]

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

        let activeGameIdString = UserDefaults.standard.string(forKey: "activeGameId") ?? ""
        let activeGameId = UUID(uuidString: activeGameIdString)

        let shouldTick = (activeGameId != nil && (resolveGameTimer(for: activeGameId!)?.isRunning ?? false))
            || playersOnPitch.contains { gameId, playerIds in
                guard !playerIds.isEmpty else { return false }
                return resolveGameTimer(for: gameId)?.isRunning ?? false
            }
        guard shouldTick else { return }

        DispatchQueue.main.async {
            self.tickCount += 1
            self.objectWillChange.send()

            if Date().timeIntervalSince(self.lastSaveTime) >= 30 {
                self.lastSaveTime = Date()
                self.onSaveRequested?()
            }
        }
    }

    // MARK: - Stint Helpers

    private func currentMatchTime(gameId: UUID) -> TimeInterval {
        if let timer = resolveGameTimer(for: gameId) {
            return timer.elapsedTime
        }
        return trackedGames[gameId]?.elapsedTime ?? 0
    }

    private func openStint(playerId: UUID, gameId: UUID, at time: TimeInterval) {
        var byPlayer = playerStintsByGame[gameId] ?? [:]
        var stints = byPlayer[playerId] ?? []
        if let last = stints.last, last.endTime == nil {
            return
        }
        stints.append(PlayerStint(startTime: time, endTime: nil))
        byPlayer[playerId] = stints
        playerStintsByGame[gameId] = byPlayer
    }

    private func closeStint(playerId: UUID, gameId: UUID, at time: TimeInterval) {
        guard var byPlayer = playerStintsByGame[gameId],
              var stints = byPlayer[playerId],
              let last = stints.last,
              last.endTime == nil
        else { return }

        stints[stints.count - 1].endTime = time
        byPlayer[playerId] = stints
        playerStintsByGame[gameId] = byPlayer
    }

    private func applyRosterChange(gameId: UUID, newPlayers: Set<UUID>) {
        let currentPlayers = playersOnPitch[gameId] ?? []
        guard currentPlayers != newPlayers else { return }

        let time = currentMatchTime(gameId: gameId)
        let added = newPlayers.subtracting(currentPlayers)
        let removed = currentPlayers.subtracting(newPlayers)

        for playerId in added {
            openStint(playerId: playerId, gameId: gameId, at: time)
        }
        for playerId in removed {
            closeStint(playerId: playerId, gameId: gameId, at: time)
        }

        playersOnPitch[gameId] = newPlayers
        objectWillChange.send()
    }

    private func fallbackTimes(for gameId: UUID, quarter: Int) -> [UUID: TimeInterval] {
        guard let game = trackedGames[gameId] else { return [:] }
        guard !game.playerPlayTimes.isEmpty else { return [:] }

        var result: [UUID: TimeInterval] = [:]
        for (playerIdString, quarterTimes) in game.playerPlayTimes {
            guard let playerId = UUID(uuidString: playerIdString) else { continue }
            result[playerId] = quarterTimes["\(quarter)"] ?? 0
        }
        return result
    }

    private func fallbackTotalTimes(for gameId: UUID) -> [UUID: TimeInterval] {
        guard let game = trackedGames[gameId] else { return [:] }
        guard !game.playerPlayTimes.isEmpty else { return [:] }

        var result: [UUID: TimeInterval] = [:]
        for (playerIdString, quarterTimes) in game.playerPlayTimes {
            guard let playerId = UUID(uuidString: playerIdString) else { continue }
            var total: TimeInterval = 0
            for value in quarterTimes.values {
                total += value
            }
            if total > 0 {
                result[playerId] = total
            }
        }
        return result
    }

    // MARK: - Time Access

    func getTime(for playerId: UUID, gameId: UUID, quarter: Int) -> TimeInterval {
        getAllTimes(for: gameId, quarter: quarter)[playerId] ?? 0
    }

    func getAllTimes(for gameId: UUID, quarter: Int) -> [UUID: TimeInterval] {
        guard let timer = resolveGameTimer(for: gameId) else {
            return fallbackTimes(for: gameId, quarter: quarter)
        }

        let elapsed = timer.elapsedTime
        let quarterDuration = TimeInterval(timer.quarterDurationInSeconds)
        let quarterStart = quarterDuration * TimeInterval(max(0, quarter - 1))
        let quarterEnd = min(quarterDuration * TimeInterval(quarter), elapsed)

        guard quarterEnd > quarterStart else { return [:] }

        let stintsByPlayer = playerStintsByGame[gameId] ?? [:]
        if stintsByPlayer.isEmpty {
            return fallbackTimes(for: gameId, quarter: quarter)
        }

        var result: [UUID: TimeInterval] = [:]
        for (playerId, stints) in stintsByPlayer {
            var total: TimeInterval = 0
            for stint in stints {
                let start = stint.startTime
                let end = stint.endTime ?? elapsed
                let overlapStart = max(start, quarterStart)
                let overlapEnd = min(end, quarterEnd)
                if overlapEnd > overlapStart {
                    total += overlapEnd - overlapStart
                }
            }
            if total > 0 {
                result[playerId] = total
            }
        }
        return result
    }

    func getAllTimesTotal(for gameId: UUID) -> [UUID: TimeInterval] {
        guard let timer = resolveGameTimer(for: gameId) else {
            return fallbackTotalTimes(for: gameId)
        }

        let elapsed = timer.elapsedTime
        let stintsByPlayer = playerStintsByGame[gameId] ?? [:]
        if stintsByPlayer.isEmpty {
            return fallbackTotalTimes(for: gameId)
        }

        var result: [UUID: TimeInterval] = [:]
        for (playerId, stints) in stintsByPlayer {
            var total: TimeInterval = 0
            for stint in stints {
                let start = stint.startTime
                let end = stint.endTime ?? elapsed
                if end > start {
                    total += end - start
                }
            }
            if total > 0 {
                result[playerId] = total
            }
        }
        return result
    }

    // MARK: - Pitch Management

    func addPlayerToPitch(_ playerId: UUID, gameId: UUID) {
        if playersOnPitch[gameId] == nil { playersOnPitch[gameId] = [] }
        let time = currentMatchTime(gameId: gameId)
        openStint(playerId: playerId, gameId: gameId, at: time)
        playersOnPitch[gameId]?.insert(playerId)
    }

    func removePlayerFromPitch(_ playerId: UUID, gameId: UUID) {
        let time = currentMatchTime(gameId: gameId)
        closeStint(playerId: playerId, gameId: gameId, at: time)
        playersOnPitch[gameId]?.remove(playerId)
    }

    func setPlayersOnPitch(_ playerIds: [UUID], gameId: UUID) {
        applyRosterChange(gameId: gameId, newPlayers: Set(playerIds))
    }

    func ensureActiveStints(gameId: UUID, playerIds: [UUID]) {
        guard resolveGameTimer(for: gameId)?.isRunning ?? false else { return }

        let time = currentMatchTime(gameId: gameId)
        var byPlayer = playerStintsByGame[gameId] ?? [:]
        var didOpen = false

        for playerId in playerIds {
            let stints = byPlayer[playerId] ?? []
            if let last = stints.last, last.endTime == nil {
                continue
            }
            openStint(playerId: playerId, gameId: gameId, at: time)
            didOpen = true
            byPlayer = playerStintsByGame[gameId] ?? [:]
        }

        if didOpen {
            objectWillChange.send()
        }
    }

    func clearPitch(for gameId: UUID) {
        let time = currentMatchTime(gameId: gameId)
        if let ids = playersOnPitch[gameId], !ids.isEmpty {
            for playerId in ids {
                closeStint(playerId: playerId, gameId: gameId, at: time)
            }
        }
        playersOnPitch[gameId] = []
    }

    // MARK: - Game Tracking

    func track(game: Game) {
        trackedGames[game.id] = game
        if playerStintsByGame[game.id] == nil {
            loadStints(from: game)
        }
    }

    // MARK: - UserDefaults Sync

    private func refreshPlayersOnPitchFromDefaults() {
        let activeGameIdString = UserDefaults.standard.string(forKey: "activeGameId") ?? ""
        guard let activeGameId = UUID(uuidString: activeGameIdString) else { return }

        guard let data = UserDefaults.standard.data(forKey: "pitchPlayers"),
              let savedPlayers = try? JSONDecoder().decode([SavedPitchPlayer].self, from: data)
        else { return }

        let playerIds = Set(savedPlayers.map { $0.playerId })
        applyRosterChange(gameId: activeGameId, newPlayers: playerIds)
    }

    func ensureActiveStintsFromDefaults(gameId: UUID) {
        guard let data = UserDefaults.standard.data(forKey: "pitchPlayers"),
              let savedPlayers = try? JSONDecoder().decode([SavedPitchPlayer].self, from: data)
        else { return }

        let playerIds = Set(savedPlayers.map { $0.playerId })
        applyRosterChange(gameId: gameId, newPlayers: playerIds)
        ensureActiveStints(gameId: gameId, playerIds: Array(playerIds))
    }

    // MARK: - Reset & Load

    func resetStints(for gameId: UUID) {
        playerStintsByGame[gameId] = [:]
    }

    func moveToQuarter(_ newQuarter: Int, gameId: UUID, previousQuarter: Int) {
        _ = newQuarter
        _ = previousQuarter
        guard let ids = playersOnPitch[gameId], !ids.isEmpty else { return }
        let time = currentMatchTime(gameId: gameId)
        for playerId in ids {
            closeStint(playerId: playerId, gameId: gameId, at: time)
            openStint(playerId: playerId, gameId: gameId, at: time)
        }
    }

    func loadStints(from game: Game) {
        let gameId = game.id
        playerStintsByGame[gameId] = [:]

        for (playerIdString, stints) in game.playerStints {
            guard let playerId = UUID(uuidString: playerIdString) else { continue }
            playerStintsByGame[gameId]?[playerId] = stints
        }
    }

    func persistStints(to game: Game) {
        let gameId = game.id
        let stintsByPlayer = playerStintsByGame[gameId] ?? [:]
        var serialized: [String: [PlayerStint]] = [:]
        for (playerId, stints) in stintsByPlayer {
            serialized[playerId.uuidString] = stints
        }
        game.playerStints = serialized
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
