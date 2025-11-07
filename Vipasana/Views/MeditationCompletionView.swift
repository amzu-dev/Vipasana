//
//  MeditationCompletionView.swift
//  Vipasana
//
//  Created by VENKATESH BALAKUMAR on 03/11/2025.
//

import SwiftUI
import Lottie

struct MeditationCompletionView: View {
    let sessionType: String
    let onDismiss: () -> Void

    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0.0
    @AppStorage("lastAnimationIndex") private var lastAnimationIndex: Int = 0

    // Available Lottie animations
    private let animations = [
        "Meditating Fox",
        "Meditating Giraffe",
        "Meditating Koala",
        "Meditating Tiger",
        "Sloth meditate"
    ]

    private var currentAnimation: String {
        // Rotate to next animation
        let newIndex = (lastAnimationIndex + 1) % animations.count
        DispatchQueue.main.async {
            lastAnimationIndex = newIndex
        }
        return animations[newIndex]
    }

    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [
                    Color(hex: "#8B9D83") ?? .mint,
                    Color(hex: "#6B7D63") ?? .green
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // Rotating meditation animal animation
                LottieView(fileName: currentAnimation, loopMode: .loop)
                    .frame(width: 250, height: 250)
                    .scaleEffect(scale)
                    .opacity(opacity)

                // Congratulations text
                VStack(spacing: 16) {
                    Text("🎉 Congratulations! 🎉")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .opacity(opacity)

                    Text("Meditation Complete")
                        .font(.title2.weight(.semibold))
                        .foregroundColor(.white.opacity(0.9))
                        .opacity(opacity)

                    Text("You've successfully completed your \(sessionType) session")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .opacity(opacity)

                    // Stats or encouragement
                    VStack(spacing: 8) {
                        HStack(spacing: 20) {
                            StatBadge(icon: "heart.fill", text: "Mindful")
                            StatBadge(icon: "sparkles", text: "Peaceful")
                            StatBadge(icon: "star.fill", text: "Complete")
                        }
                    }
                    .padding(.top, 20)
                    .opacity(opacity)
                }

                Spacer()

                // Done button
                Button {
                    onDismiss()
                } label: {
                    Text("Done")
                        .font(.headline)
                        .foregroundColor(Color(hex: "#8B9D83"))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.white)
                        .cornerRadius(16)
                        .padding(.horizontal, 40)
                }
                .opacity(opacity)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}

struct StatBadge: View {
    let icon: String
    let text: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.yellow)

            Text(text)
                .font(.caption.weight(.medium))
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(width: 80)
        .padding(.vertical, 12)
        .background(.white.opacity(0.15))
        .cornerRadius(12)
    }
}

#Preview {
    MeditationCompletionView(sessionType: "15min") {
        print("Dismissed")
    }
}
