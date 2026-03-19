//
//  SubscriptionView.swift
//  PocketShadowing
//
//  Subscription management view with purchase and restore flows
//

import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Environment(AuthManager.self) private var authManager

    var body: some View {
        ZStack {
            GradientBackground()

            ScrollView {
                VStack(spacing: 32) {
                    if authManager.isMember {
                        subscribedContent
                    } else {
                        paywallContent
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 40)
            }
        }
        .navigationTitle(L10n.subscription)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if subscriptionManager.products.isEmpty {
                await subscriptionManager.loadProducts()
            }
        }
    }

    // MARK: - Subscribed State

    private var subscribedContent: some View {
        VStack(spacing: 16) {
            Image(systemName: "crown.fill")
                .font(.system(size: 60))
                .foregroundStyle(.yellow)

            Text(L10n.alreadySubscribed)
                .font(.title2.bold())
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 60)
    }

    // MARK: - Paywall

    private var paywallContent: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.yellow)

                Text(L10n.premium)
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
            }

            // Features
            VStack(alignment: .leading, spacing: 16) {
                featureRow(L10n.subscriptionFeature1)
                featureRow(L10n.subscriptionFeature2)
                featureRow(L10n.subscriptionFeature3)
            }
            .padding(.horizontal, 8)

            // Price
            if let product = subscriptionManager.products.first {
                Text("\(product.displayPrice) \(L10n.perMonth)")
                    .font(.title3.bold())
                    .foregroundStyle(.white)
            }

            // Error message
            if case .failed(let message) = subscriptionManager.purchaseState {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            // Subscribe button
            Button {
                Task {
                    await subscriptionManager.purchase()
                }
            } label: {
                Group {
                    if subscriptionManager.purchaseState == .purchasing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text(L10n.subscribeButton)
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.appPrimary)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(subscriptionManager.products.isEmpty || subscriptionManager.purchaseState == .purchasing)

            // Restore purchases
            Button {
                Task {
                    await subscriptionManager.restorePurchases()
                }
            } label: {
                Text(L10n.restorePurchases)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
    }

    private func featureRow(_ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.title3)
            Text(text)
                .foregroundStyle(.white)
                .font(.body)
        }
    }
}

#Preview {
    NavigationStack {
        SubscriptionView()
            .environment(SubscriptionManager())
            .environment(AuthManager())
    }
}
