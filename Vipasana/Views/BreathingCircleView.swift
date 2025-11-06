//
//  BreathingCircleView.swift
//  Vipasana
//
//  Created by VENKATESH BALAKUMAR on 03/11/2025.
//

import SwiftUI

struct BreathingCircleView: View {
    @State private var isInhaling = true
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 0.6

    let settings: BreathingSettings
    let isActive: Bool
    var showReady: Bool = false

    var body: some View {
        ZStack {
            // Pulsing circle with shadow
            Circle()
                .fill(settings.circleColor)
                .frame(width: 220, height: 220)
                .scaleEffect(scale)
                .shadow(color: settings.circleColor.opacity(0.4), radius: 25)
                .opacity(opacity)

            // Inner circle for depth
            Circle()
                .stroke(settings.circleColor.opacity(0.3), lineWidth: 2)
                .frame(width: 220, height: 220)
                .scaleEffect(scale * 0.85)

            // Breath instruction text or Ready message
            VStack(spacing: 8) {
                if showReady {
                    Text("Ready")
                        .font(.title.weight(.semibold))
                        .foregroundColor(.white.opacity(0.9))

                    Text("Preparing to begin...")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                } else {
                    Text(isInhaling ? "Breathe In" : "Breathe Out")
                        .font(.title2.weight(.medium))
                        .foregroundColor(.white.opacity(0.9))

                    Text(String(format: "%.0fs", currentDuration))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
        .onChange(of: isActive) { _, newValue in
            if newValue {
                startBreathing()
            } else {
                resetBreathing()
            }
        }
        .onAppear {
            if isActive {
                startBreathing()
            }
        }
    }

    private var currentDuration: Double {
        isInhaling ? settings.inhaleDuration : settings.exhaleDuration
    }

    private func startBreathing() {
        withAnimation(.easeInOut(duration: settings.inhaleDuration)) {
            scale = 1.4
            opacity = 0.9
            isInhaling = true
        }

        Timer.scheduledTimer(withTimeInterval: settings.inhaleDuration, repeats: true) { timer in
            if !isActive {
                timer.invalidate()
                return
            }

            isInhaling.toggle()

            if isInhaling {
                withAnimation(.easeInOut(duration: settings.inhaleDuration)) {
                    scale = 1.4
                    opacity = 0.9
                }
            } else {
                withAnimation(.easeInOut(duration: settings.exhaleDuration)) {
                    scale = 1.0
                    opacity = 0.6
                }
            }
        }
    }

    private func resetBreathing() {
        withAnimation {
            scale = 1.0
            opacity = 0.6
            isInhaling = true
        }
    }
}

#Preview {
    ZStack {
        Color.mint.ignoresSafeArea()

        BreathingCircleView(
            settings: BreathingSettings(),
            isActive: true
        )
    }
}
