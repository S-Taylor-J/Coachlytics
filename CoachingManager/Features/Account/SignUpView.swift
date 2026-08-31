//
//  SignUpView.swift
//  CoachingManager
//

import SwiftUI
import AuthenticationServices

/// Email and password account creation.
struct SignUpView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var authService = AuthService.shared

    @State private var displayName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    /// Firebase's own minimum. Checked here so the user finds out before a round trip.
    private static let minimumPasswordLength = 6

    private var trimmedEmail: String { email.trimmingCharacters(in: .whitespaces) }

    private var canSubmit: Bool {
        !displayName.trimmingCharacters(in: .whitespaces).isEmpty
            && trimmedEmail.contains("@")
            && password.count >= Self.minimumPasswordLength
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()

                ScrollView {
                    VStack(spacing: 18) {
                        AppleSignInButton(label: .signUp, isDisabled: isSubmitting) { result in
                            handleAppleCompletion(result)
                        }

                        AccountOrDivider()

                        AccountFormField(
                            title: "YOUR NAME",
                            systemImage: "person.fill",
                            text: $displayName,
                            textContentType: .name
                        )

                        AccountFormField(
                            title: "EMAIL",
                            systemImage: "envelope.fill",
                            text: $email,
                            textContentType: .username,
                            keyboardType: .emailAddress
                        )

                        VStack(alignment: .leading, spacing: 6) {
                            AccountFormField(
                                title: "PASSWORD",
                                systemImage: "lock.fill",
                                text: $password,
                                placeholder: "Create a password",
                                isSecure: true,
                                textContentType: .newPassword,
                                submitLabel: .go,
                                onSubmit: submit
                            )

                            Text("At least \(Self.minimumPasswordLength) characters.")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundStyle(
                                    password.isEmpty || password.count >= Self.minimumPasswordLength
                                        ? AppTheme.mutedText(colorScheme)
                                        : AppTheme.warning
                                )
                                .padding(.leading, 4)
                        }

                        if let errorMessage {
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(AppTheme.danger)

                                Text(errorMessage)
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundStyle(AppTheme.secondaryText(colorScheme))
                                    .fixedSize(horizontal: false, vertical: true)

                                Spacer(minLength: 0)
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(AppTheme.danger.opacity(0.10))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(AppTheme.danger.opacity(0.30), lineWidth: 1)
                                    )
                            )
                        }

                        AccountPrimaryButton(
                            title: "Create Account",
                            isLoading: isSubmitting,
                            isEnabled: canSubmit,
                            action: submit
                        )
                        .padding(.top, 4)

                        Text("Your teams, games and stats stay on this device until you turn on cloud backup.")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(AppTheme.mutedText(colorScheme))
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 6)
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                    .frame(maxWidth: 520)
                    .frame(maxWidth: .infinity)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("Create Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .tint(AppTheme.brandAccent)
        }
    }

    private func handleAppleCompletion(_ result: Result<ASAuthorization, Error>) {
        errorMessage = nil
        isSubmitting = true

        Task {
            defer { isSubmitting = false }
            do {
                try await authService.completeAppleSignIn(with: result)
                dismiss()
            } catch AuthError.appleSignInCancelled {
                // The user backed out on purpose; a banner here would just be noise.
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func submit() {
        guard canSubmit, !isSubmitting else { return }
        errorMessage = nil
        isSubmitting = true

        Task {
            defer { isSubmitting = false }
            do {
                try await authService.signUp(
                    email: trimmedEmail,
                    password: password,
                    displayName: displayName.trimmingCharacters(in: .whitespacesAndNewlines)
                )
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    SignUpView()
}
