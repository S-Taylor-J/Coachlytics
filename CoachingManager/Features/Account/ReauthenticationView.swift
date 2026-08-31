//
//  ReauthenticationView.swift
//  CoachingManager
//

import SwiftUI
import AuthenticationServices

/// Collects fresh credentials before a destructive account change.
///
/// Firebase rejects account deletion on a stale session with `requiresRecentLogin`. This sheet
/// is what turns that error into a recoverable step: confirm identity, then the caller retries.
/// Which control it shows depends on how the account was created — a password field for email
/// accounts, the Apple button for Apple ones.
struct ReauthenticationView: View {
    /// Called after credentials are successfully refreshed.
    let onSuccess: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var authService = AuthService.shared

    @State private var password = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()

                ScrollView {
                    VStack(spacing: 20) {
                        VStack(spacing: 10) {
                            Image(systemName: "lock.shield.fill")
                                .font(.system(size: 34, weight: .semibold))
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(AppTheme.brandAccent)

                            Text("Confirm it's you")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundStyle(AppTheme.primaryText(colorScheme))

                            Text("For security, please sign in again before deleting your account.")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundStyle(AppTheme.secondaryText(colorScheme))
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.top, 12)

                        if authService.usesPasswordProvider {
                            AccountFormField(
                                title: "PASSWORD",
                                systemImage: "lock.fill",
                                text: $password,
                                placeholder: "Enter your password",
                                isSecure: true,
                                textContentType: .password,
                                submitLabel: .go,
                                onSubmit: submitPassword
                            )

                            AccountPrimaryButton(
                                title: "Confirm",
                                isLoading: isSubmitting,
                                isEnabled: !password.isEmpty,
                                action: submitPassword
                            )
                        }

                        if authService.usesAppleProvider {
                            AppleSignInButton(label: .continue, isDisabled: isSubmitting) { result in
                                submitApple(result)
                            }
                        }

                        if let errorMessage {
                            Text(errorMessage)
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(AppTheme.danger)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, 40)
                    .frame(maxWidth: 520)
                    .frame(maxWidth: .infinity)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("Confirm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .tint(AppTheme.brandAccent)
        }
    }

    private func submitPassword() {
        guard !password.isEmpty, !isSubmitting else { return }
        errorMessage = nil
        isSubmitting = true

        Task {
            defer { isSubmitting = false }
            do {
                try await authService.reauthenticate(password: password)
                dismiss()
                onSuccess()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func submitApple(_ result: Result<ASAuthorization, Error>) {
        errorMessage = nil
        isSubmitting = true

        Task {
            defer { isSubmitting = false }
            do {
                try await authService.reauthenticateWithApple(result: result)
                dismiss()
                onSuccess()
            } catch AuthError.appleSignInCancelled {
                // Deliberate back-out; no alert.
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    ReauthenticationView {}
}
