//
//  Club.swift
//  CoachingManager
//
//  PHASE 3 — defined now so the Firestore document shape is settled and Phase 1 code
//  (user profiles carrying `clubIds`) is written against the real type. Nothing
//  constructs or reads these yet.
//

import Foundation

/// A club that managers join to share game stats with each other.
///
/// Mirrors `clubs/{clubId}`. Joining happens by short invite code; a separate
/// `inviteCodes/{code} -> clubId` index document makes the lookup a single document read,
/// which keeps the security rules tight — a collection-wide query on `clubs` would
/// otherwise have to be permitted just to resolve a code.
struct Club: Codable, Equatable, Identifiable {
    let id: String
    var name: String
    var ownerUid: String
    var inviteCode: String
    var createdAt: Date

    init(
        id: String = UUID().uuidString,
        name: String,
        ownerUid: String,
        inviteCode: String = Club.generateInviteCode(),
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.ownerUid = ownerUid
        self.inviteCode = inviteCode
        self.createdAt = createdAt
    }

    /// Six characters from an alphabet with no 0/O or 1/I/L, so codes read aloud over a
    /// touchline don't get mistyped.
    static func generateInviteCode() -> String {
        let alphabet = "ABCDEFGHJKMNPQRSTUVWXYZ23456789"
        return String((0..<6).compactMap { _ in alphabet.randomElement() })
    }
}

extension Club {
    var documentData: [String: Any] {
        [
            "name": name,
            "ownerUid": ownerUid,
            "inviteCode": inviteCode,
            "createdAt": createdAt.timeIntervalSince1970
        ]
    }

    init(id: String, documentData data: [String: Any]) {
        self.init(
            id: id,
            name: data["name"] as? String ?? "",
            ownerUid: data["ownerUid"] as? String ?? "",
            inviteCode: data["inviteCode"] as? String ?? "",
            createdAt: (data["createdAt"] as? TimeInterval).map(Date.init(timeIntervalSince1970:)) ?? Date()
        )
    }
}
