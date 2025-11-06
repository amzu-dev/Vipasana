//
//  OnboardingWelcomeView.swift
//  Vipasana
//
//  Created by VENKATESH BALAKUMAR on 03/11/2025.
//

import SwiftUI
import Lottie

struct OnboardingWelcomeView: View {
    let onContinue: () -> Void

    @State private var currentPage = 0
    @State private var showContent = false

    private let animalAnimations = [
        "Meditating Fox",
        "Meditating Giraffe",
        "Meditating Koala",
        "Meditating Tiger",
        "Sloth meditate"
    ]

    private let pages = [
        IntroPage(
            title: "Welcome to Vipassanā",
            subtitle: "See things as they really are",
            description: "An ancient practice of watching your breath.\nSimple. Natural. Peaceful."
        ),
        IntroPage(
            title: "How It Works",
            subtitle: "Just breathe and observe",
            description: "Notice your breath flowing in and out.\nNo need to control it. Just watch."
        ),
        IntroPage(
            title: "Why It Helps",
            subtitle: "Train your mind, find peace",
            description: "Regular practice calms your mind.\nReduces stress. Brings clarity."
        ),
        IntroPage(
            title: "Ready to Begin?",
            subtitle: "Your journey starts here",
            description: "We'll guide you every step.\nStart with just 15 minutes."
        )
    ]

    var body: some View {
        ZStack {
            // Animated Background gradient
            AnimatedGradientBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Lottie Animation
                LottieView(
                    fileName: animalAnimations[currentPage % animalAnimations.count],
                    loopMode: .loop,
                    animationSpeed: 0.7
                )
                .frame(width: 280, height: 280)
                .shadow(color: .purple.opacity(0.3), radius: 20, x: 0, y: 10)
                .scaleEffect(showContent ? 1 : 0.5)
                .opacity(showContent ? 1 : 0)
                .id(currentPage) // Force refresh on page change

                Spacer()
                    .frame(height: 60)

                // Content
                VStack(spacing: 16) {
                    Text(pages[currentPage].title)
                        .font(.system(size: 34, weight: .bold))
                        .multilineTextAlignment(.center)
                        .scaleEffect(showContent ? 1 : 0.9)
                        .opacity(showContent ? 1 : 0)

                    Text(pages[currentPage].subtitle)
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .opacity(showContent ? 1 : 0)

                    Text(pages[currentPage].description)
                        .font(.body)
                        .foregroundColor(.primary.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                        .opacity(showContent ? 1 : 0)
                }
                .padding(.horizontal, 40)
                .frame(height: 200)

                Spacer()

                // Page indicators
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? Color.white : Color.white.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.bottom, 20)

                // Navigation button
                Button(action: {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()

                    if currentPage < pages.count - 1 {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            showContent = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            currentPage += 1
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                                showContent = true
                            }
                        }
                    } else {
                        onContinue()
                    }
                }) {
                    HStack(spacing: 12) {
                        Text(currentPage < pages.count - 1 ? "Continue" : "Let's Start")
                            .font(.headline)
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.title3)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: .purple.opacity(0.4), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
                .scaleEffect(showContent ? 1 : 0.9)
                .opacity(showContent ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.1)) {
                showContent = true
            }
        }
    }
}

struct IntroPage {
    let title: String
    let subtitle: String
    let description: String
}

#Preview {
    OnboardingWelcomeView(onContinue: {})
}
