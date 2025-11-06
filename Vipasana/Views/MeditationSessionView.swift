//
//  MeditationSessionView.swift
//  Vipasana
//
//  Created by VENKATESH BALAKUMAR on 03/11/2025.
//

import SwiftUI
import SwiftData

struct MeditationSessionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let totalDuration: TimeInterval // in seconds
    let sessionType: String
    let isGuided: Bool

    @AppStorage("breathingSettings") private var settingsData: Data = Data()

    @State private var timeRemaining: TimeInterval
    @State private var isActive = false
    @State private var isPaused = false
    @State private var timer: Timer?
    @State private var showingCompletion = false
    @State private var currentSession: MeditationSession?
    @State private var audioManager = AudioManager()
    @State private var guidedMeditationManager: GuidedMeditationManager?
    @State private var lastBellMinute: Int = -1
    @State private var breathingStarted = false
    @State private var showExitConfirmation = false

    private var settings: BreathingSettings {
        if let decoded = try? JSONDecoder().decode(BreathingSettings.self, from: settingsData) {
            return decoded
        }
        return BreathingSettings()
    }

    init(durationMinutes: Int, isGuided: Bool = false) {
        self.totalDuration = TimeInterval(durationMinutes * 60)
        self.sessionType = isGuided ? "\(durationMinutes)min Guided" : "\(durationMinutes)min"
        self.isGuided = isGuided
        _timeRemaining = State(initialValue: TimeInterval(durationMinutes * 60))

        // Initialize guided meditation manager if needed
        if isGuided {
            _guidedMeditationManager = State(initialValue: GuidedMeditationManager())
        }
    }

    var body: some View {
        ZStack {
            // Background
            settings.backgroundColor
                .ignoresSafeArea()

            VStack(spacing: 40) {
                // Header with close button
                HStack {
                    Button {
                        // Show confirmation only if session is active
                        if isActive {
                            showExitConfirmation = true
                        } else {
                            dismiss()
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    Spacer()
                    Text(sessionType.uppercased())
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.white.opacity(0.7))
                    Spacer()
                    Color.clear.frame(width: 44) // Balance
                }
                .padding(.horizontal)

                Spacer()

                // Timer display
                VStack(spacing: 8) {
                    Text(timeString(from: timeRemaining))
                        .font(.system(size: 56, weight: .thin, design: .rounded))
                        .foregroundColor(.white)

                    Text("remaining")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }

                // Breathing circle
                BreathingCircleView(
                    settings: settings,
                    isActive: breathingStarted && !isPaused,
                    showReady: isActive && !breathingStarted
                )
                .frame(height: 300)

                Spacer()

                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(.white.opacity(0.2))
                            .frame(height: 4)

                        Rectangle()
                            .fill(.white)
                            .frame(width: progressWidth(in: geometry.size.width), height: 4)
                    }
                }
                .frame(height: 4)
                .padding(.horizontal, 40)

                // Control buttons
                HStack(spacing: 40) {
                    if !isActive {
                        // Start button
                        Button {
                            startMeditation()
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(.white.opacity(0.2))
                                    .frame(width: 80, height: 80)

                                Image(systemName: "play.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.white)
                            }
                        }
                    } else {
                        // Pause/Resume button
                        Button {
                            togglePause()
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(.white.opacity(0.2))
                                    .frame(width: 80, height: 80)

                                Image(systemName: isPaused ? "play.fill" : "pause.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.white)
                            }
                        }

                        // Stop button
                        Button {
                            stopMeditation()
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(.white.opacity(0.2))
                                    .frame(width: 80, height: 80)

                                Image(systemName: "stop.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $showingCompletion) {
            MeditationCompletionView(sessionType: sessionType) {
                dismiss()
            }
        }
        .alert("End Session?", isPresented: $showExitConfirmation) {
            Button("Continue Meditating", role: .cancel) {}
            Button("End Session", role: .destructive) {
                stopMeditation()
                dismiss()
            }
        } message: {
            Text("Are you sure you want to end this meditation session? Your progress won't be saved.")
        }
    }

    private func progressWidth(in totalWidth: CGFloat) -> CGFloat {
        let progress = 1.0 - (timeRemaining / totalDuration)
        return totalWidth * progress
    }

    private func timeString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func startMeditation() {
        isActive = true
        isPaused = false

        // Create session record
        currentSession = MeditationSession(
            startTime: Date(),
            duration: totalDuration,
            sessionType: sessionType
        )
        if let session = currentSession {
            modelContext.insert(session)
        }

        if isGuided {
            // Guided meditation: Play intro voiceover first
            guidedMeditationManager?.playIntroVoiceover {
                // After intro, play three bell strokes
                self.audioManager.playBell(type: .triple)

                // Start timer and breathing after bells complete
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    self.breathingStarted = true
                    self.startTimer()
                }
            }
        } else {
            // Regular meditation: Wait 3 seconds then play bells
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                // Play three bell strokes (takes 3 seconds total: 0s, 1s, 2s)
                self.audioManager.playBell(type: .triple)

                // Start timer and breathing after bells complete (3 seconds for the bells)
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    self.breathingStarted = true
                    self.startTimer()
                }
            }
        }
    }

    private func togglePause() {
        isPaused.toggle()
        if isPaused {
            timer?.invalidate()
            timer = nil
        } else {
            startTimer()
        }
    }

    private func stopMeditation() {
        timer?.invalidate()
        timer = nil
        isActive = false
        isPaused = false
        breathingStarted = false
        guidedMeditationManager?.stopVoiceovers()
        dismiss()
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1

                // Check for interval bells (for non-guided sessions)
                if !isGuided {
                    checkAndPlayIntervalBell()
                }

                // Check for guided voiceovers
                if isGuided {
                    let elapsedTime = totalDuration - timeRemaining
                    guidedMeditationManager?.checkAndPlayVoiceover(elapsedSeconds: elapsedTime)
                }
            } else {
                completeMeditation()
            }
        }
    }

    private func checkAndPlayIntervalBell() {
        let elapsedTime = totalDuration - timeRemaining
        let elapsedMinutes = Int(elapsedTime / 60)

        // Play bell every 5 minutes (at 5, 10, 15, 20, etc.)
        if elapsedMinutes > 0 && elapsedMinutes % 5 == 0 && elapsedMinutes != lastBellMinute {
            // Only play if we haven't already played for this minute mark
            // and we're not at the very end (that gets 3 bells)
            let remainingMinutes = Int(timeRemaining / 60)
            if remainingMinutes > 0 {
                audioManager.playBell(type: .single)
                lastBellMinute = elapsedMinutes
            }
        }
    }

    private func completeMeditation() {
        timer?.invalidate()
        timer = nil
        isActive = false
        breathingStarted = false

        // Play three bell strokes at the end
        audioManager.playBell(type: .triple)

        // Mark session as completed
        currentSession?.completed = true
        try? modelContext.save()

        // Show completion screen after a brief delay for the bells
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            showingCompletion = true
        }
    }
}

#Preview {
    MeditationSessionView(durationMinutes: 15, isGuided: false)
        .modelContainer(for: MeditationSession.self, inMemory: true)
}
