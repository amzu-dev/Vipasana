//
//  IAPProduct.swift
//  Vipasana
//
//  Created by VENKATESH BALAKUMAR on 07/11/2025.
//

import Foundation
import StoreKit

/// In-App Purchase product identifiers and configuration
enum IAPProduct: String, CaseIterable, Identifiable {
    case monthlySubscription = "com.amzuit.vipasana.monthly"
    case yearlySubscription = "com.amzuit.vipasana.yearly"

    var id: String { rawValue }

    /// Product display name
    var displayName: String {
        switch self {
        case .monthlySubscription:
            return "Monthly Premium"
        case .yearlySubscription:
            return "Yearly Premium"
        }
    }

    /// Product description
    var description: String {
        switch self {
        case .monthlySubscription:
            return "Access all premium features"
        case .yearlySubscription:
            return "Access all premium features with 33% savings"
        }
    }

    /// Subscription period
    var period: SubscriptionPeriod {
        switch self {
        case .monthlySubscription:
            return .monthly
        case .yearlySubscription:
            return .yearly
        }
    }

    /// Trial duration in days
    var trialDays: Int {
        return 7  // 7-day free trial for all subscriptions
    }

    /// Features included in this product
    var features: [String] {
        return [
            "All meditation durations (15, 30, 45, 60 min)",
            "Guided meditation with voiceovers",
            "Cloud sync across devices",
            "All 5 completion animations",
            "Advanced breathing patterns",
            "Detailed statistics",
            "Data export",
            "Priority support"
        ]
    }

    /// Badge text for special offers
    var badgeText: String? {
        switch self {
        case .monthlySubscription:
            return nil
        case .yearlySubscription:
            return "BEST VALUE"
        }
    }

    /// Savings percentage compared to monthly
    var savingsPercentage: Int? {
        switch self {
        case .monthlySubscription:
            return nil
        case .yearlySubscription:
            return 33  // Save 33% compared to monthly
        }
    }
}

/// Extension to work with StoreKit Product
extension IAPProduct {
    /// Get formatted price from StoreKit Product
    func formattedPrice(from product: Product) -> String {
        return product.displayPrice
    }

    /// Get subscription info from StoreKit Product
    func subscriptionInfo(from product: Product) -> Product.SubscriptionInfo? {
        return product.subscription
    }
}
