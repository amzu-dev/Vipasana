//
//  OnboardingQuestionsView.swift
//  Vipasana
//
//  Created by VENKATESH BALAKUMAR on 03/11/2025.
//

import SwiftUI
import Lottie

struct OnboardingQuestionsView: View {
    let onComplete: (String, String, Int, String) -> Void

    @State private var currentStep = 0
    @State private var userName = ""
    @State private var experience = ""
    @State private var dailyGoal = 15
    @State private var preferredTime = ""

    @State private var selectedAnimal: String

    private let totalSteps = 4

    private let animalAnimations = [
        "Meditating Fox",
        "Meditating Giraffe",
        "Meditating Koala",
        "Meditating Tiger",
        "Sloth meditate"
    ]

    init(onComplete: @escaping (String, String, Int, String) -> Void) {
        self.onComplete = onComplete
        // Select a random animal on initialization
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
            // Background gradient
            AnimatedGradientBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress indicator
                ProgressView(value: Double(currentStep + 1), total: Double(totalSteps))
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .tint(.purple)

                Spacer()
                    .frame(height: 20)

                // Lottie Animation
                LottieView(fileName: selectedAnimal, loopMode: .loop, animationSpeed: 0.7)
                    .frame(width: 180, height: 180)
                    .id(currentStep) // Force refresh on step change

                Spacer()
                    .frame(height: 30)

                // Question content
                Group {
                    switch currentStep {
                    case 0:
                        NameQuestionView(name: $userName)
                    case 1:
                        ExperienceQuestionView(experience: $experience)
                    case 2:
                        GoalQuestionView(dailyGoal: $dailyGoal)
                    case 3:
                        TimeQuestionView(preferredTime: $preferredTime)
                    default:
                        EmptyView()
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

                Spacer()

                // Navigation buttons
                HStack(spacing: 16) {
                    if currentStep > 0 {
                        Button(action: goBack) {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .font(.headline)
                            .foregroundColor(.purple)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(15)
                        }
                    }

                    Button(action: goNext) {
                        HStack {
                            Text(currentStep == totalSteps - 1 ? "Get Started" : "Continue")
                            if currentStep < totalSteps - 1 {
                                Image(systemName: "chevron.right")
                            }
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            canProceed ? LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            ) : LinearGradient(
                                colors: [.gray, .gray],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(15)
                        .shadow(color: canProceed ? .purple.opacity(0.4) : .clear, radius: 10, x: 0, y: 5)
                    }
                    .disabled(!canProceed)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }

    private var canProceed: Bool {
        switch currentStep {
        case 0: return !userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case 1: return !experience.isEmpty
        case 2: return dailyGoal > 0
        case 3: return !preferredTime.isEmpty
        default: return false
        }
    }

    private func goBack() {
        withAnimation(.spring()) {
            currentStep = max(0, currentStep - 1)
            // Change animal on step change
            selectedAnimal = animalAnimations.randomElement() ?? animalAnimations[0]
        }
    }

    private func goNext() {
        if currentStep < totalSteps - 1 {
            withAnimation(.spring()) {
                currentStep += 1
                // Change animal on step change
                selectedAnimal = animalAnimations.randomElement() ?? animalAnimations[0]
            }
        } else {
            // Complete onboarding
            onComplete(userName, experience, dailyGoal, preferredTime)
        }
    }
}

// MARK: - Question Views

struct NameQuestionView: View {
    @Binding var name: String
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                Text("What should we call you?")
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)

                Text("This helps personalize your experience")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Elegant text field
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: isFocused ? .purple.opacity(0.3) : .black.opacity(0.05), radius: isFocused ? 15 : 8, x: 0, y: 4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isFocused ? Color.purple.opacity(0.5) : Color.clear, lineWidth: 2)
                    )

                TextField("", text: $name, prompt: Text("Your name or nickname").foregroundColor(.secondary.opacity(0.6)))
                    .font(.title3)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 18)
                    .focused($isFocused)
                    .submitLabel(.done)
            }
            .frame(height: 60)
        }
        .padding(.horizontal, 32)
    }
}

struct ExperienceQuestionView: View {
    @Binding var experience: String

    let options = [
        ("complete beginner", "I'm new to meditation"),
        ("some experience", "I've tried meditation a few times"),
        ("regular practice", "I meditate regularly"),
        ("experienced", "I have an established practice")
    ]

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                Text("Your meditation experience?")
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)

                Text("No judgment, just helps us guide you better")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                ForEach(options, id: \.0) { option in
                    Button(action: {
                        withAnimation {
                            experience = option.0
                        }
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(option.0.capitalized)
                                    .font(.headline)
                                Text(option.1)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if experience == option.0 {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.purple)
                            }
                        }
                        .padding()
                        .background(
                            experience == option.0
                                ? Color.purple.opacity(0.1)
                                : Color(.systemBackground)
                        )
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    experience == option.0 ? Color.purple : Color.gray.opacity(0.3),
                                    lineWidth: 2
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal)
    }
}

struct GoalQuestionView: View {
    @Binding var dailyGoal: Int

    let goalOptions = [5, 10, 15, 30, 45, 60]

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                Text("Daily meditation goal?")
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)

                Text("How many minutes would you like to meditate each day?")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(goalOptions, id: \.self) { minutes in
                    Button(action: {
                        withAnimation {
                            dailyGoal = minutes
                        }
                    }) {
                        VStack(spacing: 8) {
                            Text("\(minutes)")
                                .font(.system(size: 32, weight: .bold))
                            Text("min")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            dailyGoal == minutes
                                ? Color.purple.opacity(0.1)
                                : Color(.systemBackground)
                        )
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    dailyGoal == minutes ? Color.purple : Color.gray.opacity(0.3),
                                    lineWidth: 2
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal)
    }
}

struct TimeQuestionView: View {
    @Binding var preferredTime: String

    let timeOptions = [
        ("morning", "Morning", "sunrise.fill", "Start your day mindfully"),
        ("afternoon", "Afternoon", "sun.max.fill", "Midday reset"),
        ("evening", "Evening", "sunset.fill", "Wind down peacefully"),
        ("night", "Night", "moon.stars.fill", "Before bed ritual")
    ]

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                Text("When do you prefer to meditate?")
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)

                Text("Choose the time that works best for you")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                ForEach(timeOptions, id: \.0) { option in
                    Button(action: {
                        withAnimation {
                            preferredTime = option.0
                        }
                    }) {
                        HStack(spacing: 16) {
                            Image(systemName: option.2)
                                .font(.title2)
                                .foregroundColor(preferredTime == option.0 ? .purple : .gray)
                                .frame(width: 40)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(option.1)
                                    .font(.headline)
                                Text(option.3)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if preferredTime == option.0 {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.purple)
                            }
                        }
                        .padding()
                        .background(
                            preferredTime == option.0
                                ? Color.purple.opacity(0.1)
                                : Color(.systemBackground)
                        )
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    preferredTime == option.0 ? Color.purple : Color.gray.opacity(0.3),
                                    lineWidth: 2
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    OnboardingQuestionsView { name, exp, goal, time in
        print("Name: \(name), Experience: \(exp), Goal: \(goal), Time: \(time)")
    }
}
