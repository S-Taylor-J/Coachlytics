//
//  AuthService.swift
//  CoachingManager
//

import Foundation
import Combine
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import AuthenticationServices

/// The app's single source of truth for who is signed in.
///
/// Follows the same shape as `AppSettingsStore`: a `shared` singleton observed directly by
/// the views that need it, rather than injected. Observing it gives every screen a live
/// account state without threading a binding through the view tree.
///
/// **Runs without Firebase configured.** If `GoogleService-Info.plist` is absent the service
/// reports `.signedOut` and every operation throws `AuthError.notConfigured`, so the app still
/// builds and runs offline for anyone who hasn't set up the Firebase project yet.
@MainActor
final class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published private(set) var state: AuthState = .loading

    private var listenerHandle: AuthStateDidChangeListenerHandle?
    private let appleCoordinator = AppleSignInCoordinator()

    /// True once `FirebaseApp.configure()` has run successfully.
    var isConfigured: Bool { FirebaseApp.app() != nil }

    private var users: CollectionReference? {
        guard isConfigured else { return nil }
        return Firestore.firestore().collection("users")
    }

    private init() {
        guard isConfigured else {
            // No backend in this build — settle immediately so the launch gate doesn't
            // sit on the splash screen forever.
            state = .signedOut
            return
        }
        observeAuthState()
    }

    deinit {
        if let listenerHandle {
            Auth.auth().removeStateDidChangeListener(listenerHandle)
        }
    }

    // MARK: - Session

    private func observeAuthState() {
        listenerHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            // The listener fires on the main thread, but hop explicitly so mutating
            // `@Published` state is unambiguously main-actor isolated.
            Task { @MainActor [weak self] in
                guard let self else { return }
                guard let user else {
                    self.state = .signedOut
                    return
                }
                let profile = await self.loadOrCreateProfile(for: user)
                self.state = .signedIn(profile)
            }
        }
    }

    /// Reads `users/{uid}`, creating it if this is the first sign-in on a new account.
    ///
    /// A read failure (offline, rules) must not strand the user on the splash screen, so it
    /// falls back to a profile built from the auth record alone.
    private func loadOrCreateProfile(for user: User, displayNameHint: String? = nil) async -> UserProfile {
        let fallback = UserProfile(
            uid: user.uid,
            displayName: displayNameHint ?? user.displayName ?? "",
            email: user.email ?? ""
        )

        guard let users else { return fallback }
        let document = users.document(user.uid)

        do {
            var snapshot: DocumentSnapshot?
            try await withFirestoreTimeout { snapshot = try await document.getDocument() }

            if let data = snapshot?.data() {
                var profile = UserProfile(uid: user.uid, documentData: data)
                // Apple only supplies the name on first authorization; if we have one now
                // and the stored profile doesn't, backfill it. Best effort, and never waited
                // on -- the profile we return is already correct without it.
                if profile.displayName.isEmpty, let hint = displayNameHint, !hint.isEmpty {
                    profile.displayName = hint
                    Task { try? await document.updateData(["displayName": hint]) }
                }
                return profile
            }
            persistProfile(fallback, to: user.uid)
            return fallback
        } catch {
            return fallback
        }
    }

    /// Mirrors a profile to `users/{uid}` in the background.
    ///
    /// Never awaited by a caller that has UI waiting on it. See `withFirestoreTimeout` for why
    /// awaiting a Firestore write is a way to hang forever.
    private func persistProfile(_ profile: UserProfile, to uid: String) {
        guard let document = users?.document(uid) else { return }
        Task {
            do {
                try await withFirestoreTimeout { try await document.setData(profile.documentData) }
            } catch {
                print("[Coachlytics] users/\(uid) was not confirmed by the server: \(error)")
            }
        }
    }

    // MARK: - Email & password

    func signUp(email: String, password: String, displayName: String) async throws {
        guard isConfigured else { throw AuthError.notConfigured }
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)

            let trimmedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedName.isEmpty {
                let request = result.user.createProfileChangeRequest()
                request.displayName = trimmedName
                try? await request.commitChanges()
            }

            let profile = UserProfile(
                uid: result.user.uid,
                displayName: trimmedName,
                email: result.user.email ?? email
            )

            // The account exists the moment `createUser` returns -- the `users/{uid}` document
            // is only a mirror of it. Sign in first and write the document in the background,
            // so a Firestore that never acknowledges the write cannot strand the caller's
            // spinner on a sign-up that has, in fact, already succeeded.
            state = .signedIn(profile)
            persistProfile(profile, to: result.user.uid)
        } catch let error as AuthError {
            throw error
        } catch {
            throw Self.mapFirebaseError(error)
        }
    }

    func signIn(email: String, password: String) async throws {
        guard isConfigured else { throw AuthError.notConfigured }
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            let profile = await loadOrCreateProfile(for: result.user)
            state = .signedIn(profile)
        } catch {
            throw Self.mapFirebaseError(error)
        }
    }

    func sendPasswordReset(email: String) async throws {
        guard isConfigured else { throw AuthError.notConfigured }
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
        } catch {
            throw Self.mapFirebaseError(error)
        }
    }

    // MARK: - Sign in with Apple

    /// Configures the Apple request. Pass to `SignInWithAppleButton(onRequest:)`.
    func prepareAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        appleCoordinator.prepare(request)
    }

    /// Completes Apple sign-in. Pass the `onCompletion` result straight through.
    func completeAppleSignIn(with result: Result<ASAuthorization, Error>) async throws {
        guard isConfigured else { throw AuthError.notConfigured }

        let authorization: ASAuthorization
        switch result {
        case .success(let value):
            authorization = value
        case .failure(let error):
            throw appleCoordinator.mapFailure(error)
        }

        do {
            let (credential, fullName) = try appleCoordinator.credential(from: authorization)
            let authResult = try await Auth.auth().signIn(with: credential)
            let profile = await loadOrCreateProfile(for: authResult.user, displayNameHint: fullName)
            state = .signedIn(profile)
        } catch let error as AuthError {
            throw error
        } catch {
            throw Self.mapFirebaseError(error)
        }
    }

    // MARK: - Sign out & deletion

    func signOut() throws {
        guard isConfigured else { throw AuthError.notConfigured }
        do {
            try Auth.auth().signOut()
            state = .signedOut
        } catch {
            throw Self.mapFirebaseError(error)
        }
    }

    /// Deletes the account and its backing document.
    ///
    /// Required by App Review guideline 5.1.1(v) for any app offering account creation.
    /// The Firestore document is deleted *first*: once the auth user is gone the request is
    /// no longer authenticated and security rules will reject the delete, orphaning the row.
    ///
    /// Local SwiftData is deliberately left untouched — the coach keeps their teams, games
    /// and stats on the device.
    func deleteAccount() async throws {
        guard isConfigured else { throw AuthError.notConfigured }
        guard let user = Auth.auth().currentUser else { throw AuthError.noSignedInUser }

        do {
            if let document = users?.document(user.uid) {
                // Best effort, and bounded: if Firestore won't confirm the delete we still
                // remove the auth user. An orphaned document is a far better outcome than a
                // deletion the user asked for that never finishes.
                try? await withFirestoreTimeout { try await document.delete() }
            }
            try await user.delete()
            state = .signedOut
        } catch {
            throw Self.mapFirebaseError(error)
        }
    }

    // MARK: - Re-authentication

    /// Which sign-in providers back the current account, e.g. `password`, `apple.com`.
    /// Used to decide which re-authentication prompt to show before a destructive change.
    var currentProviderIDs: [String] {
        Auth.auth().currentUser?.providerData.map(\.providerID) ?? []
    }

    var usesPasswordProvider: Bool { currentProviderIDs.contains("password") }
    var usesAppleProvider: Bool { currentProviderIDs.contains("apple.com") }

    /// Re-authenticates a password account.
    ///
    /// Firebase requires a recent login before deleting an account. Rather than swallowing
    /// that error, the UI collects the password and calls this, then retries the delete.
    func reauthenticate(password: String) async throws {
        guard isConfigured else { throw AuthError.notConfigured }
        guard let user = Auth.auth().currentUser, let email = user.email else {
            throw AuthError.noSignedInUser
        }
        do {
            let credential = EmailAuthProvider.credential(withEmail: email, password: password)
            try await user.reauthenticate(with: credential)
        } catch {
            throw Self.mapFirebaseError(error)
        }
    }

    /// Re-authenticates an Apple account. Feed it the `SignInWithAppleButton` result.
    func reauthenticateWithApple(result: Result<ASAuthorization, Error>) async throws {
        guard isConfigured else { throw AuthError.notConfigured }
        guard let user = Auth.auth().currentUser else { throw AuthError.noSignedInUser }

        let authorization: ASAuthorization
        switch result {
        case .success(let value):
            authorization = value
        case .failure(let error):
            throw appleCoordinator.mapFailure(error)
        }

        do {
            let (credential, _) = try appleCoordinator.credential(from: authorization)
            try await user.reauthenticate(with: credential)
        } catch let error as AuthError {
            throw error
        } catch {
            throw Self.mapFirebaseError(error)
        }
    }

    // MARK: - Entitlement

    /// Mirrors the StoreKit entitlement onto the user document so backend rules can enforce
    /// paid access in Phases 2 and 3. The on-device flag alone is trivially bypassed.
    func updateEntitlement(_ entitlement: Entitlement) async {
        guard isConfigured, let profile = state.profile else { return }
        guard profile.entitlement != entitlement else { return }

        var updated = profile
        updated.entitlement = entitlement
        state = .signedIn(updated)

        guard let document = users?.document(profile.uid) else { return }
        try? await withFirestoreTimeout {
            try await document.updateData(["entitlement": entitlement.rawValue])
        }
    }

    // MARK: - Firestore timeouts

    /// Thrown when a Firestore call doesn't come back in time. Never shown to the user.
    private struct FirestoreTimeout: Error {}

    /// Runs a Firestore call with a ceiling on how long it may take.
    ///
    /// Firestore invokes a write's completion handler only once the **server** has acknowledged
    /// it. Against an unreachable backend -- no connectivity, or a project where Cloud Firestore
    /// was never provisioned -- that acknowledgement never arrives, so a bare `try await
    /// setData(...)` suspends forever and any spinner waiting on it spins forever. The write is
    /// already durable in the local cache and flushes when the backend returns, so giving up on
    /// the acknowledgement costs nothing.
    private func withFirestoreTimeout(
        _ seconds: Double = 10,
        _ operation: @escaping () async throws -> Void
    ) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask { try await operation() }
            group.addTask {
                try await Task.sleep(for: .seconds(seconds))
                throw FirestoreTimeout()
            }
            defer { group.cancelAll() }
            try await group.next()
        }
    }

    // MARK: - Error mapping

    private static func mapFirebaseError(_ error: Error) -> AuthError {
        let nsError = error as NSError
        guard nsError.domain == AuthErrorDomain else {
            return .unknown(nsError.localizedDescription)
        }

        switch nsError.code {
        case AuthErrorCode.emailAlreadyInUse.rawValue:
            return .emailAlreadyInUse
        case AuthErrorCode.invalidEmail.rawValue:
            return .invalidEmail
        case AuthErrorCode.weakPassword.rawValue:
            return .weakPassword
        case AuthErrorCode.wrongPassword.rawValue, AuthErrorCode.invalidCredential.rawValue:
            return .wrongPassword
        case AuthErrorCode.userNotFound.rawValue:
            return .userNotFound
        case AuthErrorCode.networkError.rawValue:
            return .networkUnavailable
        case AuthErrorCode.requiresRecentLogin.rawValue:
            return .requiresRecentLogin
        default:
            return .unknown(nsError.localizedDescription)
        }
    }
}
