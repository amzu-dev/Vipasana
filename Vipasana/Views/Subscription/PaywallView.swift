//
//  PaywallView.swift
//  Vipasana
//
//  Created by VENKATESH BALAKUMAR on 07/11/2025.
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var storeKit = StoreKitManager.shared

    @State private var selectedProduct: IAPProduct = .yearlySubscription
    @State private var isPurchasing = false
    @State private var showError = false

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(hex: "#8B9D83") ?? .mint,
                    Color(hex: "#6B7D63") ?? .green
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 48))
                            .foregroundColor(.white)
                            .padding(.top, 40)

                        Text("Unlock Premium")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)

                        Text("Deepen your meditation practice")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.9))
                    }

                    // Features list
                    VStack(spacing: 16) {
                        FeatureRow(icon: "infinity", title: "All Durations", description: "15, 30, 45, and 60 minute sessions")
                        FeatureRow(icon: "waveform", title: "Guided Meditation", description: "Professional voiceover guidance")
                        FeatureRow(icon: "icloud", title: "Cloud Sync", description: "Access your progress anywhere")
                        FeatureRow(icon: "chart.line.uptrend.xyaxis", title: "Detailed Stats", description: "Track streaks and insights")
                        FeatureRow(icon: "square.and.arrow.down", title: "Data Export", description: "Export your meditation history")
                    }
                    .padding(.horizontal)

                    // Subscription options
                    VStack(spacing: 12) {
                        // Yearly (recommended)
                        SubscriptionCard(
                            product: .yearlySubscription,
                            isSelected: selectedProduct == .yearlySubscription,
                            storeKitProduct: storeKit.product(for: .yearlySubscription)
                        ) {
                            selectedProduct = .yearlySubscription
                        }

                        // Monthly
                        SubscriptionCard(
                            product: .monthlySubscription,
                            isSelected: selectedProduct == .monthlySubscription,
                            storeKitProduct: storeKit.product(for: .monthlySubscription)
                        ) {
                            selectedProduct = .monthlySubscription
                        }
                    }
                    .padding(.horizontal)

                    // CTA Button
                    Button {
                        purchaseSelected()
                    } label: {
                        HStack {
                            if isPurchasing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text(storeKit.canStartTrial ? "Start 7-Day Free Trial" : "Subscribe Now")
                                    .font(.headline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.white)
                        .foregroundColor(Color(hex: "#8B9D83"))
                        .cornerRadius(16)
                    }
                    .disabled(isPurchasing)
                    .padding(.horizontal)

                    // Trial info
                    if storeKit.canStartTrial {
                        Text("Free for 7 days, then \(selectedProduct == .yearlySubscription ? "$39.99/year" : "$4.99/month"). Cancel anytime.")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    // Restore purchases
                    Button {
                        restorePurchases()
                    } label: {
                        Text("Restore Purchases")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.top, 8)

                    // Legal links
                    HStack(spacing: 16) {
                        Button("Terms") {
                            // TODO: Show terms
                        }
                        Text("•")
                        Button("Privacy") {
                            // TODO: Show privacy
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.bottom, 40)
                }
            }

            // Close button
            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding()
                }
                Spacer()
            }
        }
        .alert("Purchase Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(storeKit.errorMessage ?? "An error occurred")
        }
    }

    private func purchaseSelected() {
        guard let product = storeKit.product(for: selectedProduct) else {
            return
        }

        isPurchasing = true

        Task {
            do {
                let transaction = try await storeKit.purchase(product)
                if transaction != nil {
                    // Purchase successful
                    dismiss()
                }
            } catch {
                showError = true
            }
            isPurchasing = false
        }
    }

    private func restorePurchases() {
        Task {
            await storeKit.restorePurchases()
            if storeKit.hasPremiumAccess {
                dismiss()
            }
        }
    }
}

// MARK: - Feature Row

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }

            Spacer()
        }
        .padding()
        .background(.white.opacity(0.15))
        .cornerRadius(12)
    }
}

// MARK: - Subscription Card

struct SubscriptionCard: View {
    let product: IAPProduct
    let isSelected: Bool
    let storeKitProduct: Product?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    // Badge
                    if let badge = product.badgeText {
                        Text(badge)
                            .font(.caption2.bold())
                            .foregroundColor(.orange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.orange.opacity(0.2))
                            .cornerRadius(4)
                    }

                    // Title
                    Text(product.displayName)
                        .font(.title3.bold())
                        .foregroundColor(.white)

                    // Price
                    if let storeKitProduct = storeKitProduct {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(storeKitProduct.displayPrice)
                                .font(.title2.bold())
                                .foregroundColor(.white)

                            Text("/ \(product.period.displayName.lowercased())")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    } else {
                        Text("Loading...")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }

                    // Savings
                    if let savings = product.savingsPercentage {
                        Text("Save \(savings)%")
                            .font(.caption.bold())
                            .foregroundColor(.green)
                    }
                }

                Spacer()

                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .white.opacity(0.5))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? .white.opacity(0.25) : .white.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? .white : .clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    PaywallView()
}
