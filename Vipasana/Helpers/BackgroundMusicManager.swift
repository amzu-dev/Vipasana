//
//  BackgroundMusicManager.swift
//  Vipasana
//
//  Created by VENKATESH BALAKUMAR on 04/11/2025.
//

import Foundation
import AVFoundation

class BackgroundMusicManager {
    static let shared = BackgroundMusicManager()

    private var audioPlayer: AVAudioPlayer?

    private init() {}

    func playOnboardingMusic() {
        guard let url = Bundle.main.url(forResource: "OnboardingMusic", withExtension: "m4a") else {
            print("Failed to find onboarding music file")
            return
        }

        do {
            // Configure audio session for background playback
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)

            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.volume = 0.75 // 75% volume
            audioPlayer?.numberOfLoops = -1 // Loop indefinitely
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()

            print("Onboarding music started playing at 75% volume")
        } catch {
            print("Failed to play onboarding music: \(error)")
        }
    }

    func stopMusic() {
        audioPlayer?.stop()
        audioPlayer = nil
        print("Onboarding music stopped")
    }

    func fadeOut(duration: TimeInterval = 1.0, completion: (() -> Void)? = nil) {
        guard let player = audioPlayer, player.isPlaying else {
            completion?()
            return
        }

        let initialVolume = player.volume
        let steps = 30
        let stepDuration = duration / Double(steps)
        let volumeDecrement = initialVolume / Float(steps)

        var currentStep = 0
        let timer = Timer.scheduledTimer(withTimeInterval: stepDuration, repeats: true) { [weak self] timer in
            guard let self = self, let player = self.audioPlayer else {
                timer.invalidate()
                completion?()
                return
            }

            currentStep += 1
            let newVolume = max(0, initialVolume - (volumeDecrement * Float(currentStep)))
            player.volume = newVolume

            if currentStep >= steps || newVolume <= 0 {
                timer.invalidate()
                self.stopMusic()
                completion?()
            }
        }

        // Ensure timer runs on main run loop
        RunLoop.main.add(timer, forMode: .common)
    }

    var isPlaying: Bool {
        return audioPlayer?.isPlaying ?? false
    }
}
