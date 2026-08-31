//
//  AppleSignInCoordinator.swift
//  CoachingManager
//

import Foundation
import AuthenticationServices
import CryptoKit
import FirebaseAuth

/// Bridges `SignInWithAppleButton` to a Firebase credential.
///
/// Firebase rejects an Apple identity token unless the request carried the SHA256 hash of a
/// nonce and the raw nonce is handed back alongside the token. Keeping both halves in one
/// object is what stops those getting out of step.
///
/// Apple returns the user's full name **only on the very first authorization** for an app.
/// On every later sign-in `fullName` is nil, so the name is captured here and passed
/// straight through to the profile — there is no second chance to read it.
@MainActor
final class AppleSignInCoordinator {
    private var currentNonce: String?

    /// Configures the request. Call from `SignInWithAppleButton`'s `onRequest`.
    func prepare(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = Self.randomNonceString()
        currentNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = Self.sha256(nonce)
    }

    /// Converts a successful authorization into a Firebase credential plus the display name
    /// Apple supplied, if this is the first time the user has authorized the app.
    func credential(from authorization: ASAuthorization) throws -> (credential: AuthCredential, fullName: String?) {
        guard let nonce = currentNonce else {
            // No nonce means `prepare(_:)` never ran, so the token can't be verified.
            throw AuthError.appleSignInFailed
        }
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let tokenData = appleIDCredential.identityToken,
              let idToken = String(data: tokenData, encoding: .utf8) else {
            throw AuthError.appleSignInFailed
        }

        // Consume the nonce so a replay can't reuse it.
        currentNonce = nil

        let credential = OAuthProvider.appleCredential(
            withIDToken: idToken,
            rawNonce: nonce,
            fullName: appleIDCredential.fullName
        )

        let fullName = appleIDCredential.fullName.flatMap { components -> String? in
            let formatter = PersonNameComponentsFormatter()
            formatter.style = .default
            let name = formatter.string(from: components).trimmingCharacters(in: .whitespacesAndNewlines)
            return name.isEmpty ? nil : name
        }

        return (credential, fullName)
    }

    /// Maps the button's failure into our own error, so a user tapping Cancel isn't shown
    /// an error alert.
    func mapFailure(_ error: Error) -> AuthError {
        if let authorizationError = error as? ASAuthorizationError, authorizationError.code == .canceled {
            return .appleSignInCancelled
        }
        return .appleSignInFailed
    }

    // MARK: - Nonce

    private static func randomNonceString(length: Int = 32) -> String {
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remaining = length

        while remaining > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in
                var random: UInt8 = 0
                let status = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                // A failure here means the system RNG is unavailable; there is no safe
                // fallback for a security nonce, so fail loudly rather than weaken it.
                precondition(status == errSecSuccess, "Unable to generate secure random bytes")
                return random
            }

            for random in randoms where remaining > 0 {
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remaining -= 1
                }
            }
        }
        return result
    }

    private static func sha256(_ input: String) -> String {
        let hashed = SHA256.hash(data: Data(input.utf8))
        return hashed.map { String(format: "%02x", $0) }.joined()
    }
}
