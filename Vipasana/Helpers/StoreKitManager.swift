//
//  StoreKitManager.swift
//  Vipasana
//
//  Created by VENKATESH BALAKUMAR on 07/11/2025.
//

import Foundation
import StoreKit
import SwiftUI
import Combine

/// Manages In-App Purchases using StoreKit 2
@MainActor
class StoreKitManager: ObservableObject {
    /// Shared singleton instance
    static let shared = StoreKitManager()

    /// Available products fetched from App Store
    @Published private(set) var products: [Product] = []

    /// Currently purchased subscription products
    @Published private(set) var purchasedProducts: Set<Product> = []

    /// Current subscription status
    @Published private(set) var subscriptionStatus: SubscriptionStatus = .free

    /// Loading state
    @Published private(set) var isLoading = false

    /// Error message if any
    @Published var errorMessage: String?

    /// Task for monitoring transaction updates
    private var transactionListener: Task<Void, Error>?

    private init() {
        // Start listening for transaction updates
        transactionListener = listenForTransactions()

        Task {
            await loadProducts()
            await updateSubscriptionStatus()
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Product Loading

    /// Load products from App Store
    func loadProducts() async {
        isLoading = true
        errorMessage = nil

        do {
            // Fetch products from App Store
            let productIdentifiers = IAPProduct.allCases.map { $0.rawValue }
            products = try await Product.products(for: productIdentifiers)

            print("✅ Loaded \(products.count) products from App Store")
        } catch {
            errorMessage = "Failed to load products: \(error.localizedDescription)"
            print("❌ Error loading products: \(error)")
        }

        isLoading = false
    }

    // MARK: - Purchase

    /// Purchase a product
    func purchase(_ product: Product) async throws -> StoreKit.Transaction? {
        isLoading = true
        errorMessage = nil

        do {
            // Attempt purchase
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                // Verify the transaction
                let transaction = try checkVerified(verification)

                // Update subscription status
                await updateSubscriptionStatus()

                // Finish the transaction
                await transaction.finish()

                print("✅ Purchase successful: \(product.id)")
                return transaction

            case .userCancelled:
                print("⚠️ Purchase cancelled by user")
                return nil

            case .pending:
                print("⏳ Purchase pending approval")
                errorMessage = "Purchase is pending approval"
                return nil

            @unknown default:
                print("❌ Unknown purchase result")
                return nil
            }
        } catch StoreKitError.notAvailableInStorefront {
            errorMessage = "This product is not available in your region"
            throw error
        } catch StoreKitError.notEntitled {
            errorMessage = "You are not entitled to this product"
            throw error
        } catch {
            errorMessage = "Purchase failed: \(error.localizedDescription)"
            throw error
        }

        isLoading = false
    }

    // MARK: - Restore Purchases

    /// Restore previous purchases
    func restorePurchases() async {
        isLoading = true
        errorMessage = nil

        do {
            // Sync with App Store
            try await AppStore.sync()

            // Update subscription status
            await updateSubscriptionStatus()

            print("✅ Purchases restored successfully")
        } catch {
            errorMessage = "Failed to restore purchases: \(error.localizedDescription)"
            print("❌ Error restoring purchases: \(error)")
        }

        isLoading = false
    }

    // MARK: - Subscription Status

    /// Update current subscription status
    func updateSubscriptionStatus() async {
        var highestStatus: Product.SubscriptionInfo.Status?
        var highestProduct: Product?

        // Check all subscription products
        for product in products {
            guard let subscription = product.subscription else { continue }

            // Get subscription status
            guard let statuses = try? await subscription.status else { continue }

            for status in statuses {
                // Verify the transaction
                guard let transaction = try? checkVerified(status.transaction) else { continue }

                // Check if this is a higher priority status
                if highestStatus == nil || status.state.priority > highestStatus!.state.priority {
                    highestStatus = status
                    highestProduct = product
                }
            }
        }

        // Update subscription status based on highest priority
        if let status = highestStatus, let product = highestProduct {
            updateSubscriptionStatus(from: status, product: product)
        } else {
            subscriptionStatus = .free
        }

        print("📊 Subscription status updated: \(subscriptionStatus.displayText)")
    }

    /// Update subscription status from Product.SubscriptionInfo.Status
    private func updateSubscriptionStatus(from status: Product.SubscriptionInfo.Status, product: Product) {
        let expirationDate = status.expirationDate ?? Date()

        switch status.state {
        case .subscribed:
            // Determine if in trial
            if status.transaction.offerType == .introductory {
                let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: expirationDate).day ?? 0
                subscriptionStatus = .trial(daysRemaining: max(0, daysRemaining), endDate: expirationDate)
            } else {
                // Active subscription
                let tier = SubscriptionTier.premium
                subscriptionStatus = .active(tier: tier, endDate: expirationDate)
            }

        case .inGracePeriod:
            // Grace period counts as active
            let tier = SubscriptionTier.premium
            subscriptionStatus = .active(tier: tier, endDate: expirationDate)

        case .inBillingRetryPeriod:
            // Billing retry counts as active
            let tier = SubscriptionTier.premium
            subscriptionStatus = .active(tier: tier, endDate: expirationDate)

        case .expired:
            // Subscription expired
            let tier = SubscriptionTier.premium
            subscriptionStatus = .expired(tier: tier, expiredDate: expirationDate)

        case .revoked:
            // Subscription was revoked
            subscriptionStatus = .free

        @unknown default:
            subscriptionStatus = .free
        }
    }

    // MARK: - Transaction Monitoring

    /// Listen for transaction updates
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in StoreKit.Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)

                    // Update subscription status
                    await self.updateSubscriptionStatus()

                    // Finish the transaction
                    await transaction.finish()

                    print("✅ Transaction updated: \(transaction.productID)")
                } catch {
                    print("❌ Transaction verification failed: \(error)")
                }
            }
        }
    }

    // MARK: - Verification

    /// Verify a transaction
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreKitError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    // MARK: - Helper Functions

    /// Get product by identifier
    func product(for identifier: IAPProduct) -> Product? {
        return products.first { $0.id == identifier.rawValue }
    }

    /// Check if user has active premium access
    var hasPremiumAccess: Bool {
        return subscriptionStatus.hasAccess
    }

    /// Get trial days remaining
    var trialDaysRemaining: Int? {
        if case .trial(let days, _) = subscriptionStatus {
            return days
        }
        return nil
    }

    /// Check if in trial period
    var isInTrial: Bool {
        return subscriptionStatus.isTrialing
    }

    /// Check if user can start trial
    var canStartTrial: Bool {
        // User can start trial if they've never subscribed
        return subscriptionStatus == .free
    }
}

// MARK: - Product.SubscriptionInfo.RenewalState Priority Extension

private extension Product.SubscriptionInfo.RenewalState {
    /// Priority of subscription states (higher = better)
    var priority: Int {
        switch self {
        case .subscribed:
            return 5
        case .inGracePeriod:
            return 4
        case .inBillingRetryPeriod:
            return 3
        case .expired:
            return 2
        case .revoked:
            return 1
        @unknown default:
            return 0
        }
    }
}
