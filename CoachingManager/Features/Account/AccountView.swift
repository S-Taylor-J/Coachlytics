//
//  AccountView.swift
//  CoachingManager
//

import SwiftUI

/// The signed-in user's account screen: profile, plan, sign out, delete.
///
/// In-app account deletion is not optional — App Review guideline 5.1.1(v) requires it of any
/// app that offers account creation, which is why it ships in Phase 1 alongside sign-up rather
/// than being deferred.
struct AccountView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var authService = AuthService.shared
    @ObservedObject private var entitlements = EntitlementStore.shared

    @State private var showSignOutConfirmation = false
    @State private var showDeleteConfirmation = false
    @State private var showReauthentication = false
    @State private var showPaywall = false
    @State private var isDeleting = false
    @State private var errorMessage: String?

    private var profile: UserProfile? { authService.state.profile }

    var body: some View {
        ZStack {
            AppBackgroundView()

            ScrollView {
                VStack(spacing: 20) {
                    if let profile {
                        profileCard(profile)
                        planCard(profile)
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(AppTheme.danger)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    dangerZone
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 110)
                .frame(maxWidth: 520)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Account")
        .navigationBarTitleDisplayMode(.inline)
        .tint(AppTheme.brandAccent)
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .sheet(isPresented: $showReauthentication) {
            ReauthenticationView {
                // Credentials are fresh now, so the delete that failed can be retried.
                deleteAccount()
            }
        }
        .confirmationDialog("Sign out of Coachlytics?", isPresented: $showSignOutConfirmation, titleVisibility: .visible) {
            Button("Sign Out", role: .destructive) { signOut() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your teams, games and stats stay on this device.")
        }
        .alert("Delete your account?", isPresented: $showDeleteConfirmation) {
            Button("Delete Account", role: .destructive) { deleteAccount() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently deletes your Coachlytics account and anything stored in the cloud. Your teams, games and stats stay on this device. This can't be undone.")
        }
    }

    // MARK: - Cards

    private func profileCard(_ profile: UserProfile) -> some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.brandAccent, AppTheme.brandDeepBlue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 74, height: 74)

                Text(profile.initials)
                    .font(.system(size: 27, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .shadow(color: AppTheme.brandAccent.opacity(0.30), radius: 14, x: 0, y: 6)

            VStack(spacing: 4) {
                Text(profile.resolvedDisplayName)
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.primaryText(colorScheme))

                if !profile.email.isEmpty {
                    Text(profile.email)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.mutedText(colorScheme))
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .cardSurface(cornerRadius: 22)
    }

    private func planCard(_ profile: UserProfile) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: entitlements.isPro ? "crown.fill" : "person.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(entitlements.isPro ? AppTheme.goldAccent : AppTheme.brandAccent)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Current plan")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.mutedText(colorScheme))

                    Text(entitlements.isPro ? "Coachlytics Pro" : "Free")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.primaryText(colorScheme))
                }

                Spacer(minLength: 0)

                if !entitlements.isPro {
                    Button {
                        showPaywall = true
                    } label: {
                        Text("Upgrade")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .frame(height: 34)
                            .background(Capsule().fill(AppTheme.brandAccent))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
        }
        .cardSurface(cornerRadius: 18)
    }

    private var dangerZone: some View {
        VStack(spacing: 12) {
            Button {
                showSignOutConfirmation = true
            } label: {
                actionRowLabel(
                    title: "Sign Out",
                    icon: "rectangle.portrait.and.arrow.right",
                    tint: AppTheme.primaryText(colorScheme)
                )
            }
            .buttonStyle(.plain)
            .disabled(isDeleting)

            Button {
                showDeleteConfirmation = true
            } label: {
                ZStack {
                    actionRowLabel(
                        title: "Delete Account",
                        icon: "trash.fill",
                        tint: AppTheme.danger
                    )
                    .opacity(isDeleting ? 0 : 1)

                    if isDeleting {
                        ProgressView().tint(AppTheme.danger)
                    }
                }
            }
            .buttonStyle(.plain)
            .disabled(isDeleting)

            Text("Deleting your account doesn't remove anything saved on this device.")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.mutedText(colorScheme))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 2)
        }
    }

    private func actionRowLabel(title: String, icon: String, tint: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 26)

            Text(title)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(tint)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AppTheme.surfaceFill(colorScheme))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(AppTheme.strokeColor(colorScheme), lineWidth: 1)
                )
        )
    }

    // MARK: - Actions

    private func signOut() {
        errorMessage = nil
        do {
            try authService.signOut()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func deleteAccount() {
        errorMessage = nil
        isDeleting = true

        Task {
            defer { isDeleting = false }
            do {
                try await authService.deleteAccount()
                dismiss()
            } catch AuthError.requiresRecentLogin {
                // Firebase refuses to delete on a stale session. Collect fresh credentials
                // and come straight back here rather than dead-ending the user.
                showReauthentication = true
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    NavigationStack {
        AccountView()
    }
}
