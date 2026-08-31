//
//  WelcomeView.swift
//  CoachingManager
//

import SwiftUI
import AuthenticationServices

/// The first-launch screen.
///
/// Every route out of here is one tap: Apple, email, or skip. The skip option is styled as a
/// real, readable control rather than buried fine print — App Review guideline 5.1.1(v)
/// requires that an app whose core features work offline lets people in without an account,
/// and a skip link nobody can find is the same thing as no skip link.
struct WelcomeView: View {
    @Binding var hasSeenWelcome: Bool

    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var authService = AuthService.shared

    @State private var showSignIn = false
    @State private var showSignUp = false
    @State private var errorMessage: String?
    @State private var isAuthenticating = false

    private let benefits: [(icon: String, title: String, detail: String)] = [
        ("icloud.and.arrow.up.fill", "Back up your season", "Keep teams, games and stats safe if you change phone."),
        ("iphone.and.arrow.forward", "Use more than one device", "Pick up on the iPad exactly where the phone left off."),
        ("person.2.fill", "Share with your club", "Send game stats to other managers — coming soon.")
    ]

    var body: some View {
        ZStack {
            AppBackgroundView()

            ScrollView {
                VStack(spacing: 0) {
                    header
                        .padding(.top, 48)

                    benefitList
                        .padding(.top, 34)

                    actions
                        .padding(.top, 34)

                    skipButton
                        .padding(.top, 22)

                    footnote
                        .padding(.top, 18)
                        .padding(.bottom, 36)
                }
                .padding(.horizontal, 24)
                .frame(maxWidth: 520)
                .frame(maxWidth: .infinity)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .tint(AppTheme.brandAccent)
        .sheet(isPresented: $showSignIn) {
            SignInView()
        }
        .sheet(isPresented: $showSignUp) {
            SignUpView()
        }
        .alert("Couldn't sign in", isPresented: errorBinding) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    // MARK: - Sections

    private var header: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppTheme.brandAccent.opacity(0.16))
                    .frame(width: 92, height: 92)

                Image(systemName: "sportscourt.fill")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundStyle(AppTheme.brandAccent)
            }
            .shadow(color: AppTheme.brandAccent.opacity(0.30), radius: 18, x: 0, y: 8)

            Text("Welcome to Coachlytics")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.primaryText(colorScheme))
                .multilineTextAlignment(.center)

            Text("Create an account to back up your season and share it with your club.")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.secondaryText(colorScheme))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var benefitList: some View {
        VStack(spacing: 16) {
            ForEach(benefits, id: \.title) { benefit in
                HStack(alignment: .top, spacing: 14) {
                    Image(systemName: benefit.icon)
                        .font(.system(size: 17, weight: .semibold))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(AppTheme.brandAccent)
                        .frame(width: 30, height: 30)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(benefit.title)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(AppTheme.primaryText(colorScheme))

                        Text(benefit.detail)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(AppTheme.mutedText(colorScheme))
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)
                }
            }
        }
        .padding(18)
        .cardSurface(cornerRadius: 22)
    }

    private var actions: some View {
        VStack(spacing: 12) {
            AppleSignInButton(label: .signIn, isDisabled: isAuthenticating) { result in
                handleAppleCompletion(result)
            }

            Button {
                showSignUp = true
            } label: {
                Text("Continue with email")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(AppTheme.brandAccent)
                    )
            }
            .buttonStyle(.plain)
            .disabled(isAuthenticating)

            Button {
                showSignIn = true
            } label: {
                Text("I already have an account")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.brandAccent)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
            }
            .buttonStyle(.plain)
            .disabled(isAuthenticating)
        }
        .overlay {
            if isAuthenticating {
                ProgressView()
                    .tint(AppTheme.brandAccent)
                    .padding(20)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
    }

    private var skipButton: some View {
        VStack(spacing: 10) {
            Rectangle()
                .fill(AppTheme.strokeColor(colorScheme))
                .frame(height: 1)

            Button {
                hasSeenWelcome = true
            } label: {
                HStack(spacing: 6) {
                    Text("Continue without an account")
                    Image(systemName: "arrow.right")
                        .font(.system(size: 13, weight: .bold))
                }
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.primaryText(colorScheme))
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(AppTheme.controlFill(colorScheme))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(AppTheme.strokeColor(colorScheme), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)
            .disabled(isAuthenticating)
        }
    }

    private var footnote: some View {
        Text("Every coaching feature works without an account. You can sign in later from Settings.")
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .foregroundStyle(AppTheme.mutedText(colorScheme))
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Actions

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )
    }

    private func handleAppleCompletion(_ result: Result<ASAuthorization, Error>) {
        isAuthenticating = true
        Task {
            defer { isAuthenticating = false }
            do {
                try await authService.completeAppleSignIn(with: result)
                hasSeenWelcome = true
            } catch AuthError.appleSignInCancelled {
                // The user backed out on purpose; an alert here would just be noise.
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    WelcomeView(hasSeenWelcome: .constant(false))
}
