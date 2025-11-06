//
//  OnboardingCoordinator.swift
//  Vipasana
//
//  Created by VENKATESH BALAKUMAR on 03/11/2025.
//

import SwiftUI
import SwiftData

enum OnboardingStep {
    case welcome
    case questions
    case journey
    case celebration
    case complete
}

struct OnboardingCoordinator: View {
    @Environment(\.modelContext) private var modelContext

    @State private var currentStep: OnboardingStep = .welcome
    @State private var userName: String = ""
    @State private var experience: String = ""
    @State private var dailyGoal: Int = 15
    @State private var preferredTime: String = ""

    private let musicManager = BackgroundMusicManager.shared

    var body: some View {
        Group {
            switch currentStep {
            case .welcome:
                OnboardingWelcomeView {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentStep = .questions
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))

            case .questions:
                OnboardingQuestionsView { name, exp, goal, time in
                    // Store user data temporarily
                    userName = name
                    experience = exp
                    dailyGoal = goal
                    preferredTime = time

                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentStep = .journey
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))

            case .journey:
                MeditationJourneyView {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentStep = .celebration
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))

            case .celebration:
                WelcomeCelebrationView(userName: userName) {
                    completeOnboarding()
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .scale.combined(with: .opacity)
                ))

            case .complete:
                HomeView()
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: currentStep)
        .onAppear {
            // Start background music when onboarding begins
            if !musicManager.isPlaying {
                musicManager.playOnboardingMusic()
            }
        }
        .onDisappear {
            // Safety check: ensure music stops if view disappears
            if musicManager.isPlaying {
                musicManager.stopMusic()
            }
        }
    }

    private func completeOnboarding() {
        // Start fading out music
        musicManager.fadeOut(duration: 2.0)

        // Create and save onboarding data
        let onboardingData = OnboardingData(
            hasCompletedOnboarding: true,
            userName: userName,
            meditationExperience: experience,
            dailyGoalMinutes: dailyGoal,
            preferredTime: preferredTime,
            completedAt: Date()
        )

        modelContext.insert(onboardingData)

        do {
            try modelContext.save()
            // Delay transition to allow music to fade
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    currentStep = .complete
                }
            }
        } catch {
            print("Failed to save onboarding data: \(error)")
            // Still proceed to completion even if save fails
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    currentStep = .complete
                }
            }
        }
    }
}

#Preview {
    OnboardingCoordinator()
        .modelContainer(for: [OnboardingData.self, MeditationSession.self])
}
