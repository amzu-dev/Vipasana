//
//  GuidedMeditationManager.swift
//  Vipasana
//
//  Created by VENKATESH BALAKUMAR on 05/11/2025.
//

import Foundation
import AVFoundation

class GuidedMeditationManager {
    private var voiceoverPlayer: AVAudioPlayer?
    private let audioManager = AudioManager()

    // Track which voiceovers have been played
    private var playedVoiceovers: Set<Int> = []

    // Settings for interval bells
    var enableIntervalBells: Bool = true

    init() {
        setupAudioSession()
    }

    private func setupAudioSession() {
        do {
            // .playback category allows audio to continue when app is in background or screen is locked
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .spokenAudio,  // Optimized for voice content
                options: []
            )
            try AVAudioSession.sharedInstance().setActive(true)
            print("Guided meditation audio session configured for background playback")
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }

    // Play intro voiceover before meditation starts
    func playIntroVoiceover(completion: @escaping () -> Void) {
        playVoiceover(named: "Vipasana_guided_01", completion: completion)
    }

    // Handle voiceovers during meditation based on elapsed time
    func checkAndPlayVoiceover(elapsedSeconds: TimeInterval) {
        let minutes = Int(elapsedSeconds / 60)
        let seconds = Int(elapsedSeconds.truncatingRemainder(dividingBy: 60))

        // At 0:00 - Play guided_02 (first instruction)
        if elapsedSeconds < 1 && !playedVoiceovers.contains(0) {
            playVoiceover(named: "Vipasana_guided_02")
            playedVoiceovers.insert(0)
        }

        // At 5:00 - Play gong (if enabled), wait 1 second, play guided_03
        if minutes == 5 && seconds == 0 && !playedVoiceovers.contains(5) {
            if enableIntervalBells {
                audioManager.playBell(type: .single)
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.playVoiceover(named: "Vipasana_guided_03")
            }
            playedVoiceovers.insert(5)
        }

        // At 10:00 - Play gong (if enabled)
        if minutes == 10 && seconds == 0 && !playedVoiceovers.contains(10) {
            if enableIntervalBells {
                audioManager.playBell(type: .single)
            }
            playedVoiceovers.insert(10)
        }

        // At 15:00 - Play conclusion voiceover
        if minutes == 15 && seconds == 0 && !playedVoiceovers.contains(15) {
            playVoiceover(named: "Vipasana_guided_04")
            playedVoiceovers.insert(15)
        }
    }

    private func playVoiceover(named fileName: String, completion: (() -> Void)? = nil) {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "mp3") else {
            print("Failed to find voiceover file: \(fileName).mp3")
            completion?()
            return
        }

        do {
            voiceoverPlayer = try AVAudioPlayer(contentsOf: url)
            voiceoverPlayer?.volume = 1.0
            voiceoverPlayer?.prepareToPlay()

            if let completion = completion {
                // Create a timer to detect when playback finishes
                let duration = voiceoverPlayer?.duration ?? 0
                DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.5) {
                    completion()
                }
            }

            voiceoverPlayer?.play()
            print("Playing voiceover: \(fileName).mp3")
        } catch {
            print("Failed to play voiceover: \(error)")
            completion?()
        }
    }

    // Play conclusion voiceover after the ending triple bells
    func playCompletionVoiceover() {
        // Play after the triple bells complete (4 seconds for 3 bells at 0s, 1.5s, 3s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
            self.playVoiceover(named: "Vipasana_guided_04")
        }
    }

    func stopVoiceovers() {
        voiceoverPlayer?.stop()
        voiceoverPlayer = nil
    }

    func reset() {
        playedVoiceovers.removeAll()
        stopVoiceovers()
    }
}
