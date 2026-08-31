//
//  SyncService.swift
//  CoachingManager
//
//  PHASE 2 — protocol only. No implementation exists yet; this is here so the Phase 1
//  account and entitlement code is written against the real seam and the views never
//  learn that the backend happens to be Firebase.
//

import Foundation

/// A snapshot of everything the backend holds for one user.
struct RemoteSnapshot {
    var teams: [RemoteTeam]
    var players: [RemotePlayer]
    var games: [RemoteGame]
    var syncedAt: Date
}

/// Wire representations, kept separate from the SwiftData `@Model` classes.
///
/// SwiftData models are reference types bound to a `ModelContext` and can't be safely handed
/// to a background actor, so sync converts to and from these value types at the boundary.
struct RemoteTeam: Codable, Equatable {
    var id: UUID
    var name: String
    var playerIds: [UUID]
}

struct RemotePlayer: Codable, Equatable {
    var id: UUID
    var name: String
    var number: Int
    var positions: [String]
    var skills: [String]
}

struct RemoteGame: Codable, Equatable {
    var id: UUID
    var date: Date
    var location: String
    var notes: String
    var myTeamId: UUID?
    var myTeamName: String
    var opponentName: String
    var myTeamScore: Int
    var opponentScore: Int
    var quarters: Int
    /// Always seconds. See the note below about the legacy minutes encoding.
    var quarterDuration: Int
    var isCompleted: Bool
    var events: [GameEvent]
    var playerPlayTimes: [String: [String: TimeInterval]]
    var playerStints: [String: [PlayerStint]]
    var selectedPlayerIds: [UUID]
}

/// Backs up and restores a user's data.
///
/// Two rules for the eventual implementation:
///
/// 1. `Game` keeps its collections as JSON `Data?` columns with computed accessors
///    (`events`, `playerPlayTimes`, `playerStints`, `selectedPlayerIds`). Always go through
///    the **accessors**, never the raw `Data?`, or the encoding will differ between clients.
/// 2. `quarterDuration` carries a legacy encoding where a value <= 120 means minutes.
///    Normalise to seconds before it leaves the device — see `Game.quarterDurationInSeconds`.
protocol SyncService {
    func push(teams: [RemoteTeam], players: [RemotePlayer], games: [RemoteGame]) async throws
    func pull() async throws -> RemoteSnapshot
    func lastSyncDate() -> Date?
}
