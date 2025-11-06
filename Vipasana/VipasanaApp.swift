//
//  VipasanaApp.swift
//  Vipasana
//
//  Created by VENKATESH BALAKUMAR on 03/11/2025.
//

import SwiftUI
import SwiftData

@main
struct VipasanaApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            MeditationSession.self,
            OnboardingData.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(sharedModelContainer)
    }
}

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var onboardingData: [OnboardingData]

    var body: some View {
        Group {
            if let data = onboardingData.first, data.hasCompletedOnboarding {
                HomeView()
            } else {
                OnboardingCoordinator()
            }
        }
    }
}
