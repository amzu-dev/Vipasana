//
//  AudioManager.swift
//  Vipasana
//
//  Created by VENKATESH BALAKUMAR on 03/11/2025.
//

import AVFoundation
import Foundation
import UIKit

@MainActor
class AudioManager {
    private var audioPlayers: [AVAudioPlayer] = []

    enum BellType {
        case single
        case triple
    }

    init() {
        // Configure audio session for meditation sounds with background audio support
        do {
            // .playback category allows audio to continue when app is in background or screen is locked
            // .mixWithOthers allows other apps to play audio simultaneously if needed
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .default,
                options: []
            )
            try AVAudioSession.sharedInstance().setActive(true)
            print("Audio session configured for background playback")
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }

    func playBell(type: BellType) {
        switch type {
        case .single:
            playSystemSound(count: 1)
        case .triple:
            playSystemSound(count: 3)
        }
    }

    private func playSystemSound(count: Int) {
        // Use a gentle system sound for meditation bell
        // System Sound ID 1013 is a gentle bell-like sound
        let soundID: SystemSoundID = 1013

        for i in 0..<count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 1.0) {
                AudioServicesPlaySystemSound(soundID)

                // Add haptic feedback for better user experience
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
            }
        }
    }

    // Alternative method using synthesized bell sound
    func playGeneratedBell(type: BellType) {
        let count = type == .triple ? 3 : 1

        for i in 0..<count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 1.0) {
                self.generateAndPlayBellTone()
            }
        }
    }

    private func generateAndPlayBellTone() {
        // Generate a simple bell-like tone
        let sampleRate = 44100.0
        let duration = 1.5
        let frequency = 528.0 // Solfeggio frequency for meditation

        let samples = Int(sampleRate * duration)
        var audioData = [Float]()

        for i in 0..<samples {
            let time = Double(i) / sampleRate

            // Create bell-like sound with harmonics and decay envelope
            let fundamental = sin(2.0 * .pi * frequency * time)
            let harmonic2 = 0.5 * sin(2.0 * .pi * frequency * 2.0 * time)
            let harmonic3 = 0.3 * sin(2.0 * .pi * frequency * 3.0 * time)

            // Exponential decay envelope for bell-like quality
            let envelope = exp(-3.0 * time)

            let sample = Float((fundamental + harmonic2 + harmonic3) * envelope * 0.3)
            audioData.append(sample)
        }

        // Play the generated tone
        playAudioData(audioData, sampleRate: sampleRate)
    }

    private func playAudioData(_ data: [Float], sampleRate: Double) {
        let audioFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: sampleRate,
            channels: 1,
            interleaved: false
        )

        guard let format = audioFormat else { return }

        let frameCount = AVAudioFrameCount(data.count)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }

        buffer.frameLength = frameCount

        if let channelData = buffer.floatChannelData {
            for (index, sample) in data.enumerated() {
                channelData[0][index] = sample
            }
        }

        let audioEngine = AVAudioEngine()
        let playerNode = AVAudioPlayerNode()

        audioEngine.attach(playerNode)
        audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: format)

        do {
            try audioEngine.start()
            playerNode.play()

            playerNode.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
        } catch {
            print("Audio engine failed to start: \(error)")
        }
    }
}
