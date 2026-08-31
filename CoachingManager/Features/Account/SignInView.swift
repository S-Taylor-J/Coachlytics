//
//  SignInView.swift
//  CoachingManager
//

import SwiftUI
import AuthenticationServices

/// Email and password sign-in.
struct SignInView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var authService = AuthService.shared

    @State private var email = ""
    @State private var password = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var resetConfirmation: String?
    @State private var showSignUp = false

    private var canSubmit: Bool {
        !email.trimmingCharacters(in: .whitespaces).isEmpty && !password.isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()

                ScrollView {
                    VStack(spacing: 18) {
                        AppleSignInButton(label: .signIn, isDisabled: isSubmitting) { result in
                            handleAppleCompletion(result)
                        }

                        AccountOrDivider()

                        AccountFormField(
                            title: "EMAIL",
                            systemImage: "envelope.fill",
                            text: $email,
                            textContentType: .username,
                            keyboardType: .emailAddress
                        )

                        AccountFormField(
                            title: "PASSWORD",
                            systemImage: "lock.fill",
                            text: $password,
                            placeholder: "Enter your password",
                            isSecure: true,
                            textContentType: .password,
                            submitLabel: .go,
                            onSubmit: submit
                        )

                        if let errorMessage {
                            errorBanner(errorMessage)
                        }

                        if let resetConfirmation {
                            infoBanner(resetConfirmation)
                        }

                        AccountPrimaryButton(
                            title: "Sign In",
                            isLoading: isSubmitting,
                            isEnabled: canSubmit,
                            action: submit
                        )
                        .padding(.top, 4)

                        Button("Forgot your password?") { sendReset() }
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(AppTheme.brandAccent)
                            .disabled(email.trimmingCharacters(in: .whitespaces).isEmpty || isSubmitting)

                        Divider()
                            .overlay(AppTheme.strokeColor(colorScheme))
                            .padding(.vertical, 4)

                        Button {
                            showSignUp = true
                        } label: {
                            Text("Don't have an account? **Create one**")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundStyle(AppTheme.secondaryText(colorScheme))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                    .frame(maxWidth: 520)
                    .frame(maxWidth: .infinity)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("Sign In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .tint(AppTheme.brandAccent)
            .sheet(isPresented: $showSignUp) {
                SignUpView()
            }
        }
    }

    private func errorBanner(_ message: String) -> some View {
        banner(message, icon: "exclamationmark.triangle.fill", tint: AppTheme.danger)
    }

    private func infoBanner(_ message: String) -> some View {
        banner(message, icon: "checkmark.circle.fill", tint: AppTheme.success)
    }

    private func banner(_ message: String, icon: String, tint: Color) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(tint)

            Text(message)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.secondaryText(colorScheme))
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(tint.opacity(0.10))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(tint.opacity(0.30), lineWidth: 1)
                )
        )
    }

    private func submit() {
        guard canSubmit, !isSubmitting else { return }
        errorMessage = nil
        resetConfirmation = nil
        isSubmitting = true

        Task {
            defer { isSubmitting = false }
            do {
                try await authService.signIn(
                    email: email.trimmingCharacters(in: .whitespaces),
                    password: password
                )
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func handleAppleCompletion(_ result: Result<ASAuthorization, Error>) {
        errorMessage = nil
        resetConfirmation = nil
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

    private func sendReset() {
        let trimmed = email.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        errorMessage = nil
        resetConfirmation = nil

        Task {
            do {
                try await authService.sendPasswordReset(email: trimmed)
                resetConfirmation = "We've sent a reset link to \(trimmed)."
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    SignInView()
}
