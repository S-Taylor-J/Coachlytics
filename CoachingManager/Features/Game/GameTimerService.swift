//
//  GameTimerService.swift
//  CoachingManager
//
//  Created by Taylor Santos on 07/01/2026.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Game Timer Service (Singleton)
/// A singleton service that manages game timers across the app.
/// Timers continue running even when navigating away from the game view.
class GameTimerService: ObservableObject {
    static let shared = GameTimerService()
    
    @Published private(set) var activeTimers: [UUID: GameTimer] = [:]
    
    private init() {}
    
    // MARK: - Get or Create Timer for Game
    func timer(for game: Game) -> GameTimer {
        if let existing = activeTimers[game.id] {
            // Defer syncing to avoid publishing changes during view updates
            DispatchQueue.main.async { [weak existing] in
                existing?.syncFromGame(game)
            }
            return existing
        }
        
        let newTimer = GameTimer(game: game)
        activeTimers[game.id] = newTimer
        // Defer initial sync as well, in case this is called during a view update
        DispatchQueue.main.async { [weak newTimer] in
            newTimer?.syncFromGame(game)
        }
        return newTimer
    }
    
    // MARK: - Remove Timer
    func removeTimer(for gameId: UUID) {
        activeTimers[gameId]?.stop()
        activeTimers.removeValue(forKey: gameId)
    }
    
    // MARK: - Check if Game Has Active Timer
    func isTimerRunning(for gameId: UUID) -> Bool {
        activeTimers[gameId]?.isRunning ?? false
    }
}

// MARK: - Game Timer
class GameTimer: ObservableObject {
    let gameId: UUID
    
    @Published var isGameActive: Bool
    @Published var isRunning: Bool = false
    @Published var currentQuarter: Int
    @Published var elapsedTime: TimeInterval
    @Published var quarterElapsedTime: TimeInterval
    
    let quarters: Int
    let quarterDuration: Int // stored value (seconds for new, minutes for old games)
    
    // Computed property for actual duration in seconds (handles backwards compatibility)
    var quarterDurationInSeconds: Int {
        // If value <= 120, assume it's in minutes (old format) and convert to seconds
        // If value > 120, it's already in seconds (new format)
        quarterDuration <= 120 ? quarterDuration * 60 : quarterDuration
    }
    
    private var timer: Timer?
    private var saveCallback: ((GameTimer) -> Void)?
    private var hasActiveSession: Bool = false  // Track if timer has been used in this session
    
    init(game: Game) {
        self.gameId = game.id
        self.isGameActive = game.isGameActive
        self.currentQuarter = game.currentQuarter
        self.elapsedTime = game.elapsedTime
        self.quarterElapsedTime = game.quarterElapsedTime
        self.quarters = game.quarters
        self.quarterDuration = game.quarterDuration
        
        // Resume if it was running
        if game.isRunning && game.isGameActive && !game.isCompleted {
            startClock()
        }
    }
    
    // MARK: - Sync from Game Model
    func syncFromGame(_ game: Game) {
        // Only sync if not currently running AND no active session to avoid overwriting timer state
        // Once a game session starts, the timer is the source of truth
        if !isRunning && !hasActiveSession {
            self.isGameActive = game.isGameActive
            self.currentQuarter = game.currentQuarter
            self.elapsedTime = game.elapsedTime
            self.quarterElapsedTime = game.quarterElapsedTime
        }
    }
    
    // MARK: - Save Callback
    func onSave(_ callback: @escaping (GameTimer) -> Void) {
        self.saveCallback = callback
    }
    
    // MARK: - Formatted Time
    var formattedGameTime: String {
        let minutes = Int(elapsedTime) / 60
        let seconds = Int(elapsedTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var formattedQuarterTime: String {
        let minutes = Int(quarterElapsedTime) / 60
        let seconds = Int(quarterElapsedTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var timeRemainingInQuarter: String {
        let quarterDurationSecs = TimeInterval(quarterDurationInSeconds)
        let remaining = max(0, quarterDurationSecs - quarterElapsedTime)
        let minutes = Int(remaining) / 60
        let seconds = Int(remaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - Clock Control
    func startGame() {
        hasActiveSession = true  // Mark session as active
        isGameActive = true
        currentQuarter = 1
        elapsedTime = 0
        quarterElapsedTime = 0
        startClock()
        triggerSave()
    }
    
    func startClock() {
        guard !isRunning else { return }
        hasActiveSession = true  // Mark session as active when clock starts
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.elapsedTime += 1
                self?.quarterElapsedTime += 1
                
                // Auto-save every 10 seconds
                if Int(self?.elapsedTime ?? 0) % 10 == 0 {
                    self?.triggerSave()
                }
            }
        }
        // Ensure timer runs on common run loop mode (survives UI interactions)
        RunLoop.main.add(timer!, forMode: .common)
    }
    
    func pauseClock() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        triggerSave()
    }
    
    func stop() {
        pauseClock()
    }
    
    func endQuarter() {
        // Stop the timer without triggering a save yet
        isRunning = false
        timer?.invalidate()
        timer = nil
        
        if currentQuarter < quarters {
            currentQuarter += 1
            quarterElapsedTime = 0  // Reset quarter time for new quarter
        } else {
            endGame()
            return  // endGame already triggers save
        }
        triggerSave()
    }
    
    func previousQuarter() {
        // Go back to previous quarter
        guard currentQuarter > 1 else { return }
        
        // Stop the timer
        isRunning = false
        timer?.invalidate()
        timer = nil
        
        // Subtract current quarter time from total
        elapsedTime = max(0, elapsedTime - quarterElapsedTime)
        
        // Go back one quarter
        currentQuarter -= 1
        quarterElapsedTime = 0  // Reset quarter time
        
        triggerSave()
    }
    
    func endGame() {
        pauseClock()
        isGameActive = false
        hasActiveSession = false  // Session ends when game ends
        triggerSave()
    }
    
    func resetGame() {
        pauseClock()
        isGameActive = false
        hasActiveSession = false  // Reset session state
        currentQuarter = 1
        elapsedTime = 0
        quarterElapsedTime = 0
        triggerSave()
    }
    
    /// Reset only the quarter timer to 0, keeping the current quarter
    /// Also subtracts the quarter elapsed time from total game time
    func resetQuarterTimer() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            // Subtract the current quarter time from total elapsed time
            self.elapsedTime = max(0, self.elapsedTime - self.quarterElapsedTime)
            // Reset quarter time to 0
            self.quarterElapsedTime = 0
            self.objectWillChange.send()  // Force UI update
            self.triggerSave()
        }
    }
    
    private func triggerSave() {
        saveCallback?(self)
    }
    
    deinit {
        timer?.invalidate()
    }
}

