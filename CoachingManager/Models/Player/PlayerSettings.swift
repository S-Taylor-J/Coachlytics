//
//  PlayerSettings.swift
//  CoachingManager
//
//  Created by Taylor Santos on 06/01/2026.
//

import Foundation
import Combine

/// Configuration options for player attributes
struct PlayerOptions {
    /// Default player positions
    static let defaultPositions = [
        "Goalkeeper",
        "Defender",
        "Midfielder",
        "Forward"
    ]
    
    /// Default player skills (penalty corner roles)
    static let defaultSkills = [
        "Drag Flicker",
        "Injector",
        "Stopper",
        "PC Runner 1",
        "PC Runner 2",
        "PC Runner 3",
        "PC Lineman"
    ]
    
    /// Legacy accessors for backward compatibility
    static var positions: [String] {
        CustomOptionsManager.shared.allPositions
    }
    
    static var skills: [String] {
        CustomOptionsManager.shared.allSkills
    }
    
    private init() {}
}

// MARK: - Custom Options Manager
/// Manages custom skills and positions with persistence via UserDefaults
class CustomOptionsManager: ObservableObject {
    static let shared = CustomOptionsManager()
    
    private let customSkillsKey = "customSkills"
    private let customPositionsKey = "customPositions"
    private let hiddenDefaultSkillsKey = "hiddenDefaultSkills"
    private let hiddenDefaultPositionsKey = "hiddenDefaultPositions"
    
    @Published private(set) var customSkills: [String] = []
    @Published private(set) var customPositions: [String] = []
    @Published private(set) var hiddenDefaultSkills: Set<String> = []
    @Published private(set) var hiddenDefaultPositions: Set<String> = []
    
    private init() {
        loadCustomOptions()
    }
    
    /// Active default skills (not hidden)
    var activeDefaultSkills: [String] {
        PlayerOptions.defaultSkills.filter { !hiddenDefaultSkills.contains($0) }
    }
    
    /// Active default positions (not hidden)
    var activeDefaultPositions: [String] {
        PlayerOptions.defaultPositions.filter { !hiddenDefaultPositions.contains($0) }
    }
    
    /// All skills (active defaults + custom)
    var allSkills: [String] {
        activeDefaultSkills + customSkills
    }
    
    /// All positions (active defaults + custom)
    var allPositions: [String] {
        activeDefaultPositions + customPositions
    }
    
    // MARK: - Skills Management
    
    func addCustomSkill(_ skill: String) {
        let trimmed = skill.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty,
              !PlayerOptions.defaultSkills.contains(trimmed),
              !customSkills.contains(trimmed) else { return }
        customSkills.append(trimmed)
        saveCustomSkills()
    }
    
    func removeCustomSkill(_ skill: String) {
        customSkills.removeAll { $0 == skill }
        saveCustomSkills()
    }
    
    func isCustomSkill(_ skill: String) -> Bool {
        customSkills.contains(skill)
    }
    
    func isDefaultSkill(_ skill: String) -> Bool {
        PlayerOptions.defaultSkills.contains(skill)
    }
    
    func hideDefaultSkill(_ skill: String) {
        guard PlayerOptions.defaultSkills.contains(skill) else { return }
        hiddenDefaultSkills.insert(skill)
        saveHiddenDefaultSkills()
    }
    
    func showDefaultSkill(_ skill: String) {
        hiddenDefaultSkills.remove(skill)
        saveHiddenDefaultSkills()
    }
    
    func isDefaultSkillHidden(_ skill: String) -> Bool {
        hiddenDefaultSkills.contains(skill)
    }
    
    // MARK: - Positions Management
    
    func addCustomPosition(_ position: String) {
        let trimmed = position.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty,
              !PlayerOptions.defaultPositions.contains(trimmed),
              !customPositions.contains(trimmed) else { return }
        customPositions.append(trimmed)
        saveCustomPositions()
    }
    
    func removeCustomPosition(_ position: String) {
        customPositions.removeAll { $0 == position }
        saveCustomPositions()
    }
    
    func isCustomPosition(_ position: String) -> Bool {
        customPositions.contains(position)
    }
    
    func isDefaultPosition(_ position: String) -> Bool {
        PlayerOptions.defaultPositions.contains(position)
    }
    
    func hideDefaultPosition(_ position: String) {
        guard PlayerOptions.defaultPositions.contains(position) else { return }
        hiddenDefaultPositions.insert(position)
        saveHiddenDefaultPositions()
    }
    
    func showDefaultPosition(_ position: String) {
        hiddenDefaultPositions.remove(position)
        saveHiddenDefaultPositions()
    }
    
    func isDefaultPositionHidden(_ position: String) -> Bool {
        hiddenDefaultPositions.contains(position)
    }
    
    // MARK: - Reset
    
    func resetSkillsToDefaults() {
        customSkills.removeAll()
        hiddenDefaultSkills.removeAll()
        saveCustomSkills()
        saveHiddenDefaultSkills()
    }
    
    func resetPositionsToDefaults() {
        customPositions.removeAll()
        hiddenDefaultPositions.removeAll()
        saveCustomPositions()
        saveHiddenDefaultPositions()
    }
    
    // MARK: - Persistence
    
    private func loadCustomOptions() {
        if let data = UserDefaults.standard.data(forKey: customSkillsKey),
           let skills = try? JSONDecoder().decode([String].self, from: data) {
            customSkills = skills
        }
        
        if let data = UserDefaults.standard.data(forKey: customPositionsKey),
           let positions = try? JSONDecoder().decode([String].self, from: data) {
            customPositions = positions
        }
        
        if let data = UserDefaults.standard.data(forKey: hiddenDefaultSkillsKey),
           let hidden = try? JSONDecoder().decode(Set<String>.self, from: data) {
            hiddenDefaultSkills = hidden
        }
        
        if let data = UserDefaults.standard.data(forKey: hiddenDefaultPositionsKey),
           let hidden = try? JSONDecoder().decode(Set<String>.self, from: data) {
            hiddenDefaultPositions = hidden
        }
    }
    
    private func saveCustomSkills() {
        if let data = try? JSONEncoder().encode(customSkills) {
            UserDefaults.standard.set(data, forKey: customSkillsKey)
        }
    }
    
    private func saveCustomPositions() {
        if let data = try? JSONEncoder().encode(customPositions) {
            UserDefaults.standard.set(data, forKey: customPositionsKey)
        }
    }
    
    private func saveHiddenDefaultSkills() {
        if let data = try? JSONEncoder().encode(hiddenDefaultSkills) {
            UserDefaults.standard.set(data, forKey: hiddenDefaultSkillsKey)
        }
    }
    
    private func saveHiddenDefaultPositions() {
        if let data = try? JSONEncoder().encode(hiddenDefaultPositions) {
            UserDefaults.standard.set(data, forKey: hiddenDefaultPositionsKey)
        }
    }
}
