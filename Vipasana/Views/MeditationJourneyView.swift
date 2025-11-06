//
//  MeditationJourneyView.swift
//  Vipasana
//
//  Created by VENKATESH BALAKUMAR on 03/11/2025.
//

import SwiftUI
import Lottie

struct MeditationJourneyView: View {
    let onContinue: () -> Void

    @State private var selectedAnimal: String
    @State private var showPhases = false

    private let animalAnimations = [
        "Meditating Fox",
        "Meditating Giraffe",
        "Meditating Koala",
        "Meditating Tiger",
        "Sloth meditate"
    ]

    init(onContinue: @escaping () -> Void) {
        self.onContinue = onContinue
        _selectedAnimal = State(initialValue: [
            "Meditating Fox",
            "Meditating Giraffe",
            "Meditating Koala",
            "Meditating Tiger",
            "Sloth meditate"
        ].randomElement() ?? "Meditating Fox")
    }

    var body: some View {
        ZStack {
            // Animated gradient background
            AnimatedGradientBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 20)

                // Lottie Animation
                LottieView(fileName: selectedAnimal, loopMode: .loop, animationSpeed: 0.6)
                    .frame(width: 180, height: 180)
                    .shadow(color: .purple.opacity(0.3), radius: 20, x: 0, y: 10)

                Spacer()
                    .frame(height: 20)

                VStack(spacing: 8) {
                    Text("Your Meditation Journey")
                        .font(.system(size: 28, weight: .bold))
                        .multilineTextAlignment(.center)

                    Text("A gentle path to deeper practice")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)

                Spacer()
                    .frame(height: 20)

                // Simplified journey phases
                VStack(spacing: 12) {
                    JourneyPhaseRow(
                        number: "1",
                        title: "Days 1-7: Begin",
                        description: "15 min guided sessions",
                        color: .green
                    )
                    .opacity(showPhases ? 1 : 0)
                    .offset(y: showPhases ? 0 : 20)

                    JourneyPhaseRow(
                        number: "2",
                        title: "Days 8-21: Build",
                        description: "15 min silent meditation",
                        color: .blue
                    )
                    .opacity(showPhases ? 1 : 0)
                    .offset(y: showPhases ? 0 : 20)

                    JourneyPhaseRow(
                        number: "3",
                        title: "Days 22-45: Grow",
                        description: "45 min silent meditation",
                        color: .purple
                    )
                    .opacity(showPhases ? 1 : 0)
                    .offset(y: showPhases ? 0 : 20)

                    JourneyPhaseRow(
                        number: "4",
                        title: "Day 45+: Deepen",
                        description: "60+ min silent practice",
                        color: .orange
                    )
                    .opacity(showPhases ? 1 : 0)
                    .offset(y: showPhases ? 0 : 20)
                }
                .padding(.horizontal, 24)

                Spacer()
                    .frame(height: 16)

                // Simplified tip
                Text("Move at your own pace. What matters is showing up.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Spacer()

                Button(action: onContinue) {
                    HStack {
                        Text("I'm Ready to Begin")
                        Image(systemName: "arrow.right.circle.fill")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [.purple, .blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: .purple.opacity(0.4), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                showPhases = true
            }
        }
    }
}

struct JourneyPhaseRow: View {
    let number: String
    let title: String
    let description: String
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            // Number circle
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 40, height: 40)

                Text(number)
                    .font(.headline)
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(14)
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: color.opacity(0.15), radius: 6, x: 0, y: 3)
    }
}

struct AnimatedGradientBackground: View {
    @State private var animate = false

    var body: some View {
        LinearGradient(
            colors: [
                .purple.opacity(animate ? 0.3 : 0.5),
                .blue.opacity(animate ? 0.5 : 0.3),
                .purple.opacity(animate ? 0.4 : 0.2)
            ],
            startPoint: animate ? .topLeading : .bottomLeading,
            endPoint: animate ? .bottomTrailing : .topTrailing
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                animate.toggle()
            }
        }
    }
}

#Preview {
    MeditationJourneyView(onContinue: {})
}
