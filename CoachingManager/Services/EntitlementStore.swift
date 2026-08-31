//
//  EntitlementStore.swift
//  CoachingManager
//

import Foundation
import Combine
import StoreKit

/// Owns the user's subscription state.
///
/// Same singleton shape as `AppSettingsStore` and `AuthService`, so views observe it directly.
///
/// Phase 1 wires the full StoreKit 2 flow but gates nothing — cloud sync and clubs don't exist
/// yet, so `PaywallView` is reachable only from Settings and simply describes what's coming.
/// The `guard EntitlementStore.shared.isPro` checks land in Phase 2.
///
/// `isPro` is a **UI hint only**. It lives on the device and is therefore trivially bypassed;
/// every entitlement change is mirrored to `users/{uid}.entitlement` so the backend can be the
/// real gate once there is server data to protect.
@MainActor
final class EntitlementStore: ObservableObject {
    static let shared = EntitlementStore()

    enum ProductID {
        static let monthly = "com.ts.coachlytics.pro.monthly"
        static let yearly = "com.ts.coachlytics.pro.yearly"
        static let all: [String] = [monthly, yearly]
    }

    @Published private(set) var isPro = false
    @Published private(set) var products: [Product] = []
    @Published private(set) var isLoadingProducts = false
    @Published private(set) var purchaseInFlight = false

    private var updatesTask: Task<Void, Never>?

    private init() {
        // Must start before any purchase so transactions approved outside the app
        // (Ask to Buy, a purchase interrupted by a crash) are still observed.
        updatesTask = listenForTransactions()

        Task {
            await refreshEntitlements()
            await loadProducts()
        }
    }

    deinit {
        updatesTask?.cancel()
    }

    // MARK: - Products

    func loadProducts() async {
        guard !isLoadingProducts else { return }
        isLoadingProducts = true
        defer { isLoadingProducts = false }

        do {
            let fetched = try await Product.products(for: ProductID.all)
            // Cheapest first, so the monthly option leads regardless of App Store ordering.
            products = fetched.sorted { $0.price < $1.price }
        } catch {
            // Nothing to show is the correct outcome here; the paywall renders an
            // "unavailable" state rather than an error the coach can't act on.
            products = []
        }
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async throws {
        guard !purchaseInFlight else { return }
        purchaseInFlight = true
        defer { purchaseInFlight = false }

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            await refreshEntitlements()
        case .userCancelled, .pending:
            // `.pending` covers Ask to Buy — the transaction listener picks it up on approval.
            break
        @unknown default:
            break
        }
    }

    func restore() async throws {
        try await AppStore.sync()
        await refreshEntitlements()
    }

    // MARK: - Entitlements

    /// Recomputes `isPro` from the current entitlements and mirrors the result to the
    /// signed-in user's document.
    func refreshEntitlements() async {
        var active = false

        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result) else { continue }
            guard ProductID.all.contains(transaction.productID) else { continue }
            // A revoked or expired transaction still appears here, so check both.
            if transaction.revocationDate == nil,
               !(transaction.expirationDate.map { $0 < Date() } ?? false) {
                active = true
            }
        }

        isPro = active
        await AuthService.shared.updateEntitlement(active ? .pro : .free)
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                guard let transaction = try? await self.checkVerified(result) else { continue }
                await transaction.finish()
                await self.refreshEntitlements()
            }
        }
    }

    /// StoreKit 2 verifies the signature for us; an unverified result means the payload was
    /// tampered with and must not grant access.
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    enum StoreError: LocalizedError {
        case failedVerification

        var errorDescription: String? {
            "That purchase couldn't be verified. Please try again."
        }
    }
}
