//
//  AuthState.swift
//  CoachingManager
//

import Foundation

/// Where the user stands with their account.
///
/// `.loading` matters at launch: Firebase restores a persisted session asynchronously, so
/// without a distinct loading case every signed-in user would see a flash of the welcome
/// screen before being bounced into the app.
enum AuthState: Equatable {
    case loading
    case signedOut
    case signedIn(UserProfile)

    var profile: UserProfile? {
        if case .signedIn(let profile) = self { return profile }
        return nil
    }

    var isSignedIn: Bool { profile != nil }

    var isLoading: Bool { self == .loading }
}

/// Errors surfaced to the user during account flows.
///
/// Firebase's own errors are wrapped so the UI never shows raw SDK text, which is often
/// phrased for developers rather than coaches.
enum AuthError: LocalizedError, Equatable {
    case notConfigured
    case emailAlreadyInUse
    case invalidEmail
    case weakPassword
    case wrongPassword
    case userNotFound
    case networkUnavailable
    case requiresRecentLogin
    case appleSignInFailed
    case appleSignInCancelled
    case noSignedInUser
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Accounts aren't available in this build yet."
        case .emailAlreadyInUse:
            return "That email already has an account. Try signing in instead."
        case .invalidEmail:
            return "That doesn't look like a valid email address."
        case .weakPassword:
            return "Passwords need to be at least 6 characters."
        case .wrongPassword:
            return "That password doesn't match. Try again or reset it."
        case .userNotFound:
            return "No account found for that email."
        case .networkUnavailable:
            return "You appear to be offline. Check your connection and try again."
        case .requiresRecentLogin:
            return "For security, please sign in again before making this change."
        case .appleSignInFailed:
            return "Sign in with Apple didn't complete. Please try again."
        case .appleSignInCancelled:
            return "Sign in with Apple was cancelled."
        case .noSignedInUser:
            return "You need to be signed in to do that."
        case .unknown(let message):
            return message
        }
    }
}
