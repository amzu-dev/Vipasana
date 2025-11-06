//
//  WelcomeCelebrationView.swift
//  Vipasana
//
//  Created by VENKATESH BALAKUMAR on 03/11/2025.
//

import SwiftUI
import Lottie

struct WelcomeCelebrationView: View {
    let userName: String
    let onComplete: () -> Void

    @State private var selectedAnimal: String
    @State private var showContent = false
    @State private var showConfetti = false
    @State private var pulseAnimation = false

    private let animalAnimations = [
        "Meditating Fox",
        "Meditating Giraffe",
        "Meditating Koala",
        "Meditating Tiger",
        "Sloth meditate"
    ]

    init(userName: String, onComplete: @escaping () -> Void) {
        self.userName = userName
        self.onComplete = onComplete
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

            // Confetti effect
            if showConfetti {
                ConfettiView()
                    .ignoresSafeArea()
            }

            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 30)

                // Lottie Animation with pulse effect
                ZStack {
                    // Pulse circles
                    ForEach(0..<3) { index in
                        Circle()
                            .stroke(Color.purple.opacity(0.2), lineWidth: 2)
                            .frame(width: 200, height: 200)
                            .scaleEffect(pulseAnimation ? 1.2 : 0.8)
                            .opacity(pulseAnimation ? 0 : 0.4)
                            .animation(
                                .easeOut(duration: 2.0)
                                .repeatForever(autoreverses: false)
                                .delay(Double(index) * 0.6),
                                value: pulseAnimation
                            )
                    }

                    LottieView(fileName: selectedAnimal, loopMode: .loop, animationSpeed: 0.5)
                        .frame(width: 200, height: 200)
                }
                .scaleEffect(showContent ? 1 : 0.5)
                .opacity(showContent ? 1 : 0)

                Spacer()
                    .frame(height: 30)

                // Celebration message
                VStack(spacing: 8) {
                    Text("Welcome, \(userName)!")
                        .font(.system(size: 32, weight: .bold))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Text("You're All Set!")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .scaleEffect(showContent ? 1 : 0.8)
                .opacity(showContent ? 1 : 0)
                .padding(.horizontal, 32)

                Spacer()
                    .frame(height: 24)

                // Simple message
                VStack(spacing: 12) {
                    Text("Your journey begins now")
                        .font(.headline)

                    Text("Every moment of stillness is a gift.\nStart with 15 minutes and grow from there.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 40)
                .offset(y: showContent ? 0 : 20)
                .opacity(showContent ? 1 : 0)

                Spacer()

                Button(action: {
                    // Add haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()

                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        onComplete()
                    }
                }) {
                    HStack(spacing: 12) {
                        Text("Begin My Practice")
                            .font(.headline)
                        Image(systemName: "arrow.right.circle.fill")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(
                            colors: [.purple, .blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: .purple.opacity(0.5), radius: 15, x: 0, y: 8)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 50)
                .scaleEffect(showContent ? 1 : 0.8)
                .opacity(showContent ? 1 : 0)
            }
        }
        .onAppear {
            // Stagger animations for a delightful entrance
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                    showContent = true
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showConfetti = true
                pulseAnimation = true
            }
        }
    }
}

struct CelebrationCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 50, height: 50)

                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: color.opacity(0.15), radius: 10, x: 0, y: 5)
    }
}

struct ConfettiView: View {
    @State private var confettiPieces: [ConfettiPiece] = []

    var body: some View {
        ZStack {
            ForEach(confettiPieces) { piece in
                Circle()
                    .fill(piece.color)
                    .frame(width: piece.size, height: piece.size)
                    .position(piece.position)
                    .opacity(piece.opacity)
            }
        }
        .onAppear {
            createConfetti()
        }
    }

    func createConfetti() {
        let colors: [Color] = [.purple, .blue, .pink, .orange, .yellow, .green]

        for _ in 0..<30 {
            let randomX = CGFloat.random(in: 0...UIScreen.main.bounds.width)
            let randomDelay = Double.random(in: 0...0.5)

            let piece = ConfettiPiece(
                id: UUID(),
                color: colors.randomElement() ?? .purple,
                size: CGFloat.random(in: 5...10),
                position: CGPoint(x: randomX, y: -20),
                opacity: 1.0
            )

            confettiPieces.append(piece)

            DispatchQueue.main.asyncAfter(deadline: .now() + randomDelay) {
                animateConfetti(piece: piece)
            }
        }
    }

    func animateConfetti(piece: ConfettiPiece) {
        withAnimation(.linear(duration: 3.0)) {
            if let index = confettiPieces.firstIndex(where: { $0.id == piece.id }) {
                confettiPieces[index].position.y = UIScreen.main.bounds.height + 50
                confettiPieces[index].opacity = 0
            }
        }
    }
}

struct ConfettiPiece: Identifiable {
    let id: UUID
    let color: Color
    let size: CGFloat
    var position: CGPoint
    var opacity: Double
}

#Preview {
    WelcomeCelebrationView(userName: "Alex", onComplete: {})
}
