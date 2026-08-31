//
//  PaywallView.swift
//  CoachingManager
//

import SwiftUI
import StoreKit

/// The Coachlytics Pro upsell.
///
/// Phase 1 sells the subscription but gates nothing — cloud sync and clubs don't exist yet, so
/// the copy is explicit that those features are on the way. The real
/// `guard EntitlementStore.shared.isPro` checks arrive with Phase 2.
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var entitlements = EntitlementStore.shared
    @ObservedObject private var authService = AuthService.shared

    @State private var selectedProductID: String?
    @State private var errorMessage: String?
    @State private var isRestoring = false

    private let features: [(icon: String, title: String, detail: String)] = [
        ("icloud.and.arrow.up.fill", "Cloud backup", "Your teams, games and stats saved off-device."),
        ("arrow.triangle.2.circlepath", "Multi-device sync", "Same season on your iPhone and iPad."),
        ("person.2.fill", "Clubs", "Create or join a club and share game stats with other managers."),
        ("square.and.arrow.up.fill", "Stat sharing", "Send a game's full breakdown to a fellow coach.")
    ]

    private var selectedProduct: Product? {
        guard let selectedProductID else { return entitlements.products.first }
        return entitlements.products.first { $0.id == selectedProductID } ?? entitlements.products.first
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()

                ScrollView {
                    VStack(spacing: 24) {
                        header
                        featureList

                        if entitlements.isPro {
                            activeState
                        } else {
                            productPicker
                            purchaseControls
                        }

                        if let errorMessage {
                            Text(errorMessage)
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(AppTheme.danger)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        legalFootnote
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                    .frame(maxWidth: 520)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Coachlytics Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .tint(AppTheme.brandAccent)
        }
        .task {
            if entitlements.products.isEmpty { await entitlements.loadProducts() }
            selectedProductID = selectedProductID ?? entitlements.products.first?.id
        }
    }

    // MARK: - Sections

    private var header: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppTheme.goldAccent.opacity(0.16))
                    .frame(width: 76, height: 76)

                Image(systemName: "crown.fill")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(AppTheme.goldAccent)
            }

            Text(entitlements.isPro ? "You're on Pro" : "Take your season further")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.primaryText(colorScheme))
                .multilineTextAlignment(.center)

            Text(entitlements.isPro
                 ? "Thanks for supporting Coachlytics."
                 : "Back up everything and share it with your club.")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.secondaryText(colorScheme))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    private var featureList: some View {
        VStack(spacing: 15) {
            ForEach(features, id: \.title) { feature in
                HStack(alignment: .top, spacing: 13) {
                    Image(systemName: feature.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(AppTheme.brandAccent)
                        .frame(width: 26)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(feature.title)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(AppTheme.primaryText(colorScheme))

                        Text(feature.detail)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(AppTheme.mutedText(colorScheme))
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)
                }
            }
        }
        .padding(18)
        .cardSurface(cornerRadius: 20)
    }

    private var activeState: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundStyle(AppTheme.success)
            Text("Subscription active")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.primaryText(colorScheme))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 52)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AppTheme.success.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(AppTheme.success.opacity(0.30), lineWidth: 1)
                )
        )
    }

    @ViewBuilder
    private var productPicker: some View {
        if entitlements.isLoadingProducts {
            ProgressView()
                .tint(AppTheme.brandAccent)
                .frame(height: 80)
        } else if entitlements.products.isEmpty {
            // Products come back empty until they exist in App Store Connect, or when the
            // StoreKit test configuration isn't selected in the scheme.
            Text("Subscriptions aren't available right now. Please try again later.")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.mutedText(colorScheme))
                .multilineTextAlignment(.center)
                .padding(.vertical, 12)
        } else {
            VStack(spacing: 10) {
                ForEach(entitlements.products, id: \.id) { product in
                    productRow(product)
                }
            }
        }
    }

    private func productRow(_ product: Product) -> some View {
        let isSelected = selectedProduct?.id == product.id

        return Button {
            selectedProductID = product.id
        } label: {
            HStack(spacing: 13) {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(isSelected ? AppTheme.brandAccent : AppTheme.mutedText(colorScheme))

                VStack(alignment: .leading, spacing: 2) {
                    Text(product.displayName)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.primaryText(colorScheme))

                    if !product.description.isEmpty {
                        Text(product.description)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(AppTheme.mutedText(colorScheme))
                    }
                }

                Spacer(minLength: 0)

                Text(product.displayPrice)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.primaryText(colorScheme))
            }
            .padding(15)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(AppTheme.surfaceFill(colorScheme))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(
                                isSelected ? AppTheme.brandAccent.opacity(0.55) : AppTheme.strokeColor(colorScheme),
                                lineWidth: isSelected ? 1.5 : 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var purchaseControls: some View {
        VStack(spacing: 12) {
            AccountPrimaryButton(
                title: "Subscribe",
                isLoading: entitlements.purchaseInFlight,
                isEnabled: selectedProduct != nil,
                action: purchase
            )

            Button {
                restore()
            } label: {
                if isRestoring {
                    ProgressView().tint(AppTheme.brandAccent)
                } else {
                    Text("Restore Purchases")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.brandAccent)
                }
            }
            .buttonStyle(.plain)
            .disabled(isRestoring)
        }
    }

    private var legalFootnote: some View {
        VStack(spacing: 6) {
            if !authService.state.isSignedIn {
                Text("Sign in to keep your subscription when you change device.")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.warning)
                    .multilineTextAlignment(.center)
            }

            Text("Subscriptions renew automatically until cancelled. Manage or cancel any time in your Apple Account settings.")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.mutedText(colorScheme))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Actions

    private func purchase() {
        guard let product = selectedProduct else { return }
        errorMessage = nil

        Task {
            do {
                try await entitlements.purchase(product)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func restore() {
        errorMessage = nil
        isRestoring = true

        Task {
            defer { isRestoring = false }
            do {
                try await entitlements.restore()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    PaywallView()
}
