//
//  PlayerTimeService.swift
//  CoachingManager
//
//  Created by Taylor Santos on 02/03/2026.
//

import Foundation
import SwiftUI
import Combine

/// A singleton service that tracks player play times in sync with the game timer.
/// Continues running even when navigating away from PitchView.
class PlayerTimeService: ObservableObject {
    static let shared = PlayerTimeService()
    
    /// Player times per game and quarter: [GameID: [Quarter: [PlayerID: TimeInterval]]]
    @Published private(set) var playerTimes: [UUID: [Int: [UUID: TimeInterval]]] = [:]
    
    /// Players currently on pitch per game: [GameID: Set<PlayerID>]
    @Published var playersOnPitch: [UUID: Set<UUID>] = [:]
    
    /// Tick counter for forcing UI updates
    @Published private(set) var tickCount: Int = 0
    
    /// Callback to request save (set by PitchView)
    var onSaveRequested: (() -> Void)?
    
    private var timer: Timer?
    private var lastSaveTime: Date = Date()
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        startTimer()
    }
    
    // MARK: - Timer Management
    
    private func startTimer() {
        timer?.invalidate()
        
        let newTimer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(newTimer, forMode: .common)
        timer = newTimer
    }
    
    private func tick() {
        var didUpdate = false
        
        // Iterate through all games with players on pitch
        for (gameId, playerIds) in playersOnPitch {
            guard !playerIds.isEmpty else { continue }
            
            // Get the game timer for this game
            guard let gameTimer = GameTimerService.shared.activeTimers[gameId],
                  gameTimer.isRunning else { continue }
            
            let quarter = gameTimer.currentQuarter
            
            // Increment time for each player on pitch
            for playerId in playerIds {
                let currentTime = getTime(for: playerId, gameId: gameId, quarter: quarter)
                setTimeInternal(currentTime + 1, for: playerId, gameId: gameId, quarter: quarter)
                didUpdate = true
            }
        }
        
        // Manually trigger objectWillChange to notify observers
        if didUpdate {
            DispatchQueue.main.async {
                self.tickCount += 1
                self.objectWillChange.send()
                
                // Auto-save every 30 seconds
                if Date().timeIntervalSince(self.lastSaveTime) >= 30 {
                    self.lastSaveTime = Date()
                    self.onSaveRequested?()
                }
            }
        }
    }
    
    // MARK: - Time Access
    
    func getTime(for playerId: UUID, gameId: UUID, quarter: Int) -> TimeInterval {
        playerTimes[gameId]?[quarter]?[playerId] ?? 0
    }
    
    // Internal setter that doesn't trigger objectWillChange (called from tick)
    private func setTimeInternal(_ time: TimeInterval, for playerId: UUID, gameId: UUID, quarter: Int) {
        if playerTimes[gameId] == nil {
            playerTimes[gameId] = [:]
        }
        if playerTimes[gameId]?[quarter] == nil {
            playerTimes[gameId]?[quarter] = [:]
        }
        playerTimes[gameId]?[quarter]?[playerId] = time
    }
    
    func setTime(_ time: TimeInterval, for playerId: UUID, gameId: UUID, quarter: Int) {
        setTimeInternal(time, for: playerId, gameId: gameId, quarter: quarter)
        objectWillChange.send()
    }
    
    func getAllTimes(for gameId: UUID, quarter: Int) -> [UUID: TimeInterval] {
        playerTimes[gameId]?[quarter] ?? [:]
    }
    
    // MARK: - Pitch Management
    
    func addPlayerToPitch(_ playerId: UUID, gameId: UUID) {
        if playersOnPitch[gameId] == nil {
            playersOnPitch[gameId] = []
        }
        playersOnPitch[gameId]?.insert(playerId)
    }
    
    func removePlayerFromPitch(_ playerId: UUID, gameId: UUID) {
        playersOnPitch[gameId]?.remove(playerId)
    }
    
    func setPlayersOnPitch(_ playerIds: [UUID], gameId: UUID) {
        playersOnPitch[gameId] = Set(playerIds)
    }
    
    func clearPitch(for gameId: UUID) {
        playersOnPitch[gameId] = []
    }
    
    // MARK: - Reset & Load
    
    func resetTimes(for gameId: UUID, quarter: Int) {
        playerTimes[gameId]?[quarter] = [:]
    }
    
    func resetAllTimes(for gameId: UUID) {
        playerTimes[gameId] = [:]
    }
    
    func loadTimes(from game: Game) {
        let gameId = game.id
        playerTimes[gameId] = [:]
        
        for (playerIdString, quarterTimes) in game.playerPlayTimes {
            guard let playerId = UUID(uuidString: playerIdString) else { continue }
            
            for (quarterString, time) in quarterTimes {
                guard let quarter = Int(quarterString) else { continue }
                
                if playerTimes[gameId] == nil {
                    playerTimes[gameId] = [:]
                }
                if playerTimes[gameId]?[quarter] == nil {
                    playerTimes[gameId]?[quarter] = [:]
                }
                playerTimes[gameId]?[quarter]?[playerId] = time
            }
        }
    }
    
    // MARK: - Background Time Sync
    
    func addBackgroundTime(_ seconds: TimeInterval, gameId: UUID, quarter: Int) {
        guard let playerIds = playersOnPitch[gameId] else { return }
        
        for playerId in playerIds {
            let currentTime = getTime(for: playerId, gameId: gameId, quarter: quarter)
            setTime(currentTime + seconds, for: playerId, gameId: gameId, quarter: quarter)
        }
    }
    
    deinit {
        timer?.invalidate()
    }
}
