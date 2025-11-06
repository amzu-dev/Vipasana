//
//  HomeView.swift
//  Vipasana
//
//  Created by VENKATESH BALAKUMAR on 03/11/2025.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    var body: some View {
        TabView {
            HomeTabView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            HistoryView()
                .tabItem {
                    Label("History", systemImage: "calendar")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
    }
}

struct HomeTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MeditationSession.startTime, order: .reverse) private var sessions: [MeditationSession]

    @State private var selectedSession: SessionType?

    enum SessionType: Hashable {
        case regular(minutes: Int)
        case guided(minutes: Int)
    }

    private let durations = [15, 30, 45, 60]

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient - matching onboarding vibrant colors
                LinearGradient(
                    colors: [
                        .purple.opacity(0.4),
                        .blue.opacity(0.5),
                        .purple.opacity(0.3)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 30) {
                        // Header
                        VStack(spacing: 8) {
                            Text("Vipassanā")
                                .font(.system(size: 48, weight: .thin, design: .serif))
                                .foregroundColor(.white)

                            Text("Mindfulness Meditation")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(.top, 60)

                        // Guided meditation card (featured)
                        VStack(spacing: 16) {
                            NavigationLink(value: SessionType.guided(minutes: 15)) {
                                GuidedMeditationCard()
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 20)

                        // Regular duration cards
                        VStack(spacing: 16) {
                            ForEach(durations, id: \.self) { duration in
                                NavigationLink(value: SessionType.regular(minutes: duration)) {
                                    DurationCard(minutes: duration)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 20)

                        // Session history
                        if !sessions.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Recent Sessions")
                                    .font(.headline)
                                    .foregroundColor(.white.opacity(0.9))
                                    .padding(.horizontal, 24)

                                ForEach(completedSessions.prefix(5)) { session in
                                    SessionHistoryRow(session: session)
                                }
                            }
                            .padding(.top, 30)
                        }

                        Spacer(minLength: 100)
                    }
                }
            }
            .navigationDestination(for: SessionType.self) { sessionType in
                switch sessionType {
                case .regular(let minutes):
                    MeditationSessionView(durationMinutes: minutes, isGuided: false)
                case .guided(let minutes):
                    MeditationSessionView(durationMinutes: minutes, isGuided: true)
                }
            }
        }
    }

    private var completedSessions: [MeditationSession] {
        sessions.filter { $0.completed }
    }
}

struct GuidedMeditationCard: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "waveform.circle.fill")
                        .font(.title3)
                        .foregroundColor(.white)

                    Text("15 Minutes Guided")
                        .font(.title2.weight(.semibold))
                        .foregroundColor(.white)
                }

                Text("Gentle voice-guided Vipassanā practice")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }

            Spacer()

            Image(systemName: "arrow.right.circle.fill")
                .font(.title2)
                .foregroundColor(.white.opacity(0.9))
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [.purple.opacity(0.6), .blue.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.3), lineWidth: 1)
                )
        )
        .shadow(color: .purple.opacity(0.3), radius: 15, y: 8)
    }
}

struct DurationCard: View {
    let minutes: Int

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("\(minutes) Minutes")
                    .font(.title2.weight(.semibold))
                    .foregroundColor(.white)

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }

            Spacer()

            Image(systemName: "arrow.right.circle.fill")
                .font(.title2)
                .foregroundColor(.white.opacity(0.9))
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
    }

    private var description: String {
        switch minutes {
        case 15:
            return "Quick session for beginners"
        case 30:
            return "Standard practice session"
        case 45:
            return "Deep meditation practice"
        case 60:
            return "Extended contemplation"
        default:
            return "Meditation session"
        }
    }
}

struct SessionHistoryRow: View {
    let session: MeditationSession

    var body: some View {
        HStack {
            Circle()
                .fill(.white.opacity(0.3))
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 4) {
                Text(session.sessionType)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white)

                Text(formatDate(session.startTime))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()

            if session.completed {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 8)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    HomeView()
        .modelContainer(for: MeditationSession.self, inMemory: true)
}
