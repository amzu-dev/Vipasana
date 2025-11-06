//
//  MeditationCompletionView.swift
//  Vipasana
//
//  Created by VENKATESH BALAKUMAR on 03/11/2025.
//

import SwiftUI

struct MeditationCompletionView: View {
    let sessionType: String
    let onDismiss: () -> Void

    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0.0

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

                // Buddha illustration
                LaughingBuddhaView()
                    .frame(width: 200, height: 200)
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

struct LaughingBuddhaView: View {
    var body: some View {
        ZStack {
            // Buddha body - rounded sitting pose
            VStack(spacing: 0) {
                // Head
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#FFD699") ?? .orange, Color(hex: "#FFB84D") ?? .orange],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 80, height: 80)
                    .overlay {
                        // Smiling face
                        VStack(spacing: 8) {
                            // Eyes - closed happy eyes
                            HStack(spacing: 20) {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(.black)
                                    .frame(width: 16, height: 4)
                                    .rotationEffect(.degrees(15))

                                RoundedRectangle(cornerRadius: 10)
                                    .fill(.black)
                                    .frame(width: 16, height: 4)
                                    .rotationEffect(.degrees(-15))
                            }
                            .offset(y: -5)

                            // Big smile
                            Path { path in
                                path.move(to: CGPoint(x: 20, y: 10))
                                path.addQuadCurve(
                                    to: CGPoint(x: 50, y: 10),
                                    control: CGPoint(x: 35, y: 20)
                                )
                            }
                            .stroke(.black, lineWidth: 3)
                            .frame(width: 50, height: 20)
                            .offset(y: 5)
                        }
                    }
                    .offset(y: 10)

                // Body - round belly
                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#FFB84D") ?? .orange, Color(hex: "#FF9900") ?? .orange],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 120, height: 140)
                    .overlay {
                        // Robe detail
                        Circle()
                            .stroke(.white.opacity(0.3), lineWidth: 2)
                            .frame(width: 90, height: 90)
                            .offset(y: 10)
                    }
            }

            // Arms in meditation pose
            HStack(spacing: 120) {
                // Left arm
                Capsule()
                    .fill(Color(hex: "#FFB84D") ?? .orange)
                    .frame(width: 30, height: 80)
                    .rotationEffect(.degrees(20))
                    .offset(x: 5, y: 40)

                // Right arm
                Capsule()
                    .fill(Color(hex: "#FFB84D") ?? .orange)
                    .frame(width: 30, height: 80)
                    .rotationEffect(.degrees(-20))
                    .offset(x: -5, y: 40)
            }

            // Glow/aura effect
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [.yellow.opacity(0.3), .orange.opacity(0.2), .clear],
                        startPoint: .center,
                        endPoint: .bottom
                    ),
                    lineWidth: 15
                )
                .frame(width: 180, height: 180)
                .blur(radius: 10)
        }
        .frame(width: 200, height: 200)
    }
}

#Preview {
    MeditationCompletionView(sessionType: "15min") {
        print("Dismissed")
    }
}
