//
//  SubscriptionStatus.swift
//  Vipasana
//
//  Created by VENKATESH BALAKUMAR on 07/11/2025.
//

import Foundation

/// Represents the user's subscription status and tier
enum SubscriptionStatus: Codable, Equatable {
    case free
    case trial(daysRemaining: Int, endDate: Date)
    case active(tier: SubscriptionTier, endDate: Date)
    case expired(tier: SubscriptionTier, expiredDate: Date)

    /// Check if user has access to premium features
    var hasAccess: Bool {
        switch self {
        case .free, .expired:
            return false
        case .trial, .active:
            return true
        }
    }

    /// Check if currently in trial
    var isTrialing: Bool {
        if case .trial = self {
            return true
        }
        return false
    }

    /// Check if subscription is active (not trial)
    var isActive: Bool {
        if case .active = self {
            return true
        }
        return false
    }

    /// Get display text for subscription status
    var displayText: String {
        switch self {
        case .free:
            return "Free"
        case .trial(let days, _):
            return "\(days) day\(days == 1 ? "" : "s") left in trial"
        case .active(let tier, _):
            return tier.displayName
        case .expired(let tier, _):
            return "\(tier.displayName) (Expired)"
        }
    }

    /// Get the subscription tier if active or trial
    var tier: SubscriptionTier? {
        switch self {
        case .free:
            return nil
        case .trial:
            return .premium  // Trial always gives premium access
        case .active(let tier, _), .expired(let tier, _):
            return tier
        }
    }
}

/// Subscription tiers available in the app
enum SubscriptionTier: String, Codable, CaseIterable {
    case free
    case premium

    var displayName: String {
        switch self {
        case .free:
            return "Free"
        case .premium:
            return "Premium"
        }
    }
}

/// Billing period for subscriptions
enum SubscriptionPeriod: String, Codable {
    case monthly
    case yearly
    case lifetime

    var displayName: String {
        switch self {
        case .monthly:
            return "Monthly"
        case .yearly:
            return "Yearly"
        case .lifetime:
            return "Lifetime"
        }
    }

    var duration: String {
        switch self {
        case .monthly:
            return "1 month"
        case .yearly:
            return "1 year"
        case .lifetime:
            return "Forever"
        }
    }
}
