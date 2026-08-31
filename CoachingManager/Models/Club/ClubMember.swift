//
//  ClubMember.swift
//  CoachingManager
//
//  PHASE 3 — see the note in Club.swift. Not wired up yet.
//

import Foundation

/// A manager's membership of a club. Mirrors `clubs/{clubId}/members/{uid}`.
///
/// Membership is its own subcollection document rather than an array on the club so that
/// security rules can check `exists(/clubs/$(clubId)/members/$(request.auth.uid))` in a
/// single read, and so a club can grow past the size of one document.
struct ClubMember: Codable, Equatable, Identifiable {
    enum Role: String, Codable, Equatable {
        case owner
        case manager

        var displayName: String {
            switch self {
            case .owner:   return "Owner"
            case .manager: return "Manager"
            }
        }
    }

    let uid: String
    var displayName: String
    var role: Role
    var joinedAt: Date

    var id: String { uid }

    init(uid: String, displayName: String, role: Role = .manager, joinedAt: Date = Date()) {
        self.uid = uid
        self.displayName = displayName
        self.role = role
        self.joinedAt = joinedAt
    }
}

extension ClubMember {
    var documentData: [String: Any] {
        [
            "displayName": displayName,
            "role": role.rawValue,
            "joinedAt": joinedAt.timeIntervalSince1970
        ]
    }

    init(uid: String, documentData data: [String: Any]) {
        self.init(
            uid: uid,
            displayName: data["displayName"] as? String ?? "",
            role: Role(rawValue: data["role"] as? String ?? "") ?? .manager,
            joinedAt: (data["joinedAt"] as? TimeInterval).map(Date.init(timeIntervalSince1970:)) ?? Date()
        )
    }
}
