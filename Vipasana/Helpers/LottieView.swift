//
//  LottieView.swift
//  Vipasana
//
//  Created by VENKATESH BALAKUMAR on 03/11/2025.
//

import SwiftUI
import Lottie

struct LottieView: UIViewRepresentable {
    let fileName: String
    let loopMode: LottieLoopMode
    let animationSpeed: CGFloat

    init(fileName: String, loopMode: LottieLoopMode = .loop, animationSpeed: CGFloat = 1.0) {
        self.fileName = fileName
        self.loopMode = loopMode
        self.animationSpeed = animationSpeed
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        let animationView = LottieAnimationView()

        // Extract just the filename without path
        let justFileName = fileName.components(separatedBy: "/").last ?? fileName

        // Try to load the animation from bundle
        Task {
            do {
                // Try loading as DotLottie file
                if let url = Bundle.main.url(forResource: justFileName, withExtension: "lottie") {
                    let dotLottieFile = try await DotLottieFile.named(justFileName, bundle: .main)
                    if let firstAnimation = await dotLottieFile.animations.first {
                        await MainActor.run {
                            animationView.animation = firstAnimation.animation
                            animationView.contentMode = .scaleAspectFit
                            animationView.loopMode = loopMode
                            animationView.animationSpeed = animationSpeed
                            animationView.play()
                        }
                    }
                }
                // Try loading as regular Lottie JSON
                else if let animation = LottieAnimation.named(justFileName, bundle: .main) {
                    await MainActor.run {
                        animationView.animation = animation
                        animationView.contentMode = .scaleAspectFit
                        animationView.loopMode = loopMode
                        animationView.animationSpeed = animationSpeed
                        animationView.play()
                    }
                }
            } catch {
                print("Failed to load animation '\(fileName)': \(error)")
            }
        }

        animationView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(animationView)

        NSLayoutConstraint.activate([
            animationView.heightAnchor.constraint(equalTo: view.heightAnchor),
            animationView.widthAnchor.constraint(equalTo: view.widthAnchor)
        ])

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // No updates needed
    }
}
