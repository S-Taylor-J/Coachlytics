//
//  UserProfile.swift
//  CoachingManager
//
//  The app-side mirror of a `users/{uid}` document.
//

import Foundation

/// Which tier the signed-in user is on.
///
/// The on-device value is a cache of what the backend believes. It is safe to use for
/// showing or hiding UI, but never as the only gate on a paid feature — see `EntitlementStore`.
enum Entitlement: String, Codable, Equatable {
    case free
    case pro

    var displayName: String {
        switch self {
        case .free: return "Free"
        case .pro:  return "Pro"
        }
    }
}

/// A user's account record.
///
/// Deliberately free of any Firebase import: dates cross the wire as epoch seconds rather
/// than `Timestamp` so the whole `Models/` layer stays backend-agnostic and Phase 2 can put
/// a different `SyncService` behind it without touching these types.
struct UserProfile: Codable, Equatable, Identifiable {
    let uid: String
    var displayName: String
    var email: String
    var createdAt: Date
    var entitlement: Entitlement
    /// Populated in Phase 3. Present now so the document shape never has to change.
    var clubIds: [String]

    var id: String { uid }

    init(
        uid: String,
        displayName: String,
        email: String,
        createdAt: Date = Date(),
        entitlement: Entitlement = .free,
        clubIds: [String] = []
    ) {
        self.uid = uid
        self.displayName = displayName
        self.email = email
        self.createdAt = createdAt
        self.entitlement = entitlement
        self.clubIds = clubIds
    }

    /// A display name that is never empty, falling back to the local part of the email.
    var resolvedDisplayName: String {
        let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { return trimmed }
        if let localPart = email.split(separator: "@").first, !localPart.isEmpty {
            return String(localPart)
        }
        return "Coach"
    }

    /// Initials for the avatar bubble, e.g. "Taylor Santos" -> "TS".
    var initials: String {
        let parts = resolvedDisplayName
            .split(separator: " ")
            .prefix(2)
            .compactMap { $0.first }
        let joined = String(parts).uppercased()
        return joined.isEmpty ? "C" : joined
    }
}

// MARK: - Dictionary mapping

extension UserProfile {
    private enum Field {
        static let displayName = "displayName"
        static let email = "email"
        static let createdAt = "createdAt"
        static let entitlement = "entitlement"
        static let clubIds = "clubIds"
    }

    /// The payload written to `users/{uid}`. The uid itself is the document id, so it is
    /// not duplicated in the body.
    var documentData: [String: Any] {
        [
            Field.displayName: displayName,
            Field.email: email,
            Field.createdAt: createdAt.timeIntervalSince1970,
            Field.entitlement: entitlement.rawValue,
            Field.clubIds: clubIds
        ]
    }

    /// Rebuilds a profile from a stored document, tolerating missing fields so that a
    /// partially written or older document still yields a usable account rather than nil.
    init(uid: String, documentData data: [String: Any]) {
        let rawEntitlement = data[Field.entitlement] as? String ?? Entitlement.free.rawValue
        self.init(
            uid: uid,
            displayName: data[Field.displayName] as? String ?? "",
            email: data[Field.email] as? String ?? "",
            createdAt: (data[Field.createdAt] as? TimeInterval).map(Date.init(timeIntervalSince1970:)) ?? Date(),
            entitlement: Entitlement(rawValue: rawEntitlement) ?? .free,
            clubIds: data[Field.clubIds] as? [String] ?? []
        )
    }
}
