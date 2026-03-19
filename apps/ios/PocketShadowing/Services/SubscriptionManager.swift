//
//  SubscriptionManager.swift
//  PocketShadowing
//

import Foundation
import StoreKit

enum PurchaseState: Equatable {
    case idle
    case purchasing
    case purchased
    case failed(String)
}

@Observable
@MainActor
class SubscriptionManager {
    var products: [Product] = []
    var purchaseState: PurchaseState = .idle
    var isSubscribed = false

    private let profileRepository = ProfileRepository()
    private nonisolated(unsafe) var updateListenerTask: Task<Void, Never>?

    static let subscriptionProductId = "com.pocketshadowing.premium.monthly"

    init() {
        updateListenerTask = Task {
            await listenForTransactions()
        }
        Task {
            await loadProducts()
            await checkSubscriptionStatus()
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    /// Load subscription products from the App Store
    func loadProducts() async {
        do {
            let loaded = try await Product.products(for: [Self.subscriptionProductId])
            products = loaded
            print("[SubscriptionManager] Loaded \(loaded.count) products: \(loaded.map { $0.id })")
        } catch {
            print("[SubscriptionManager] Failed to load products: \(error)")
        }
    }

    /// Purchase the subscription
    func purchase() async {
        guard let product = products.first else { return }

        purchaseState = .purchasing
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await updateSubscriptionStatus(isActive: true)
                purchaseState = .purchased
            case .userCancelled:
                purchaseState = .idle
            case .pending:
                purchaseState = .idle
            @unknown default:
                purchaseState = .idle
            }
        } catch {
            print("Purchase failed: \(error)")
            purchaseState = .failed(error.localizedDescription)
        }
    }

    /// Restore previous purchases
    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await checkSubscriptionStatus()
        } catch {
            print("Restore failed: \(error)")
            purchaseState = .failed(error.localizedDescription)
        }
    }

    /// Check current subscription status from Transaction.currentEntitlements
    func checkSubscriptionStatus() async {
        var hasActiveSubscription = false

        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result),
               transaction.productID == Self.subscriptionProductId,
               transaction.revocationDate == nil {
                hasActiveSubscription = true
                break
            }
        }

        await updateSubscriptionStatus(isActive: hasActiveSubscription)
    }

    // MARK: - Private

    private func listenForTransactions() async {
        for await result in Transaction.updates {
            if let transaction = try? checkVerified(result) {
                await transaction.finish()
                await checkSubscriptionStatus()
            }
        }
    }

    private func updateSubscriptionStatus(isActive: Bool) async {
        isSubscribed = isActive
        do {
            try await profileRepository.updateMembershipStatus(isMember: isActive)
        } catch {
            print("Failed to sync membership status: \(error)")
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let value):
            return value
        }
    }
}
