//
//  SettingsView.swift
//  Vipasana
//
//  Created by VENKATESH BALAKUMAR on 03/11/2025.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("breathingSettings") private var settingsData: Data = Data()

    @Query private var onboardingData: [OnboardingData]

    @State private var settings: BreathingSettings
    @State private var backgroundColor: Color
    @State private var circleColor: Color
    @State private var showPreview = false
    @State private var userName: String = ""
    @State private var selectedRatio: BreathRatio = .balanced

    enum BreathRatio: String, CaseIterable {
        case traditional = "4:6"
        case balanced = "6:6"

        var inhale: Double {
            switch self {
            case .traditional: return 4.0
            case .balanced: return 6.0
            }
        }

        var exhale: Double {
            switch self {
            case .traditional: return 6.0
            case .balanced: return 6.0
            }
        }

        var description: String {
            switch self {
            case .traditional: return "Traditional (4s in, 6s out)"
            case .balanced: return "Balanced (6s in, 6s out)"
            }
        }
    }

    init() {
        let initialSettings: BreathingSettings
        if let data = UserDefaults.standard.data(forKey: "breathingSettings"),
           let decoded = try? JSONDecoder().decode(BreathingSettings.self, from: data) {
            initialSettings = decoded
        } else {
            initialSettings = BreathingSettings()
        }

        _settings = State(initialValue: initialSettings)
        _backgroundColor = State(initialValue: initialSettings.backgroundColor)
        _circleColor = State(initialValue: initialSettings.circleColor)

        // Determine initial ratio based on settings
        if initialSettings.inhaleDuration == 4.0 && initialSettings.exhaleDuration == 6.0 {
            _selectedRatio = State(initialValue: .traditional)
        } else {
            _selectedRatio = State(initialValue: .balanced)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                    Section("Profile") {
                        HStack {
                            Text("Name")
                            Spacer()
                            TextField("Your name", text: $userName)
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(.secondary)
                        }
                    }

                    Section {
                        Picker("Rhythm", selection: $selectedRatio) {
                            ForEach(BreathRatio.allCases, id: \.self) { ratio in
                                Text(ratio.description).tag(ratio)
                            }
                        }
                        .pickerStyle(.menu)
                        .onChange(of: selectedRatio) { _, newValue in
                            settings.inhaleDuration = newValue.inhale
                            settings.exhaleDuration = newValue.exhale
                        }

                        HStack {
                            Image(systemName: "wind")
                                .foregroundColor(.purple)
                            Text("Inhale")
                            Spacer()
                            Text("\(Int(settings.inhaleDuration))s")
                                .foregroundColor(.secondary)
                        }

                        HStack {
                            Image(systemName: "leaf")
                                .foregroundColor(.green)
                            Text("Exhale")
                            Spacer()
                            Text("\(Int(settings.exhaleDuration))s")
                                .foregroundColor(.secondary)
                        }
                    } header: {
                        Text("Breathing Pattern")
                    } footer: {
                        Text("Choose your preferred breathing rhythm. Traditional (4:6) follows classic Vipassanā, Balanced (6:6) offers equal inhale and exhale.")
                            .font(.caption)
                    }

                    Section("Appearance") {
                        ColorPicker("Background Color", selection: $backgroundColor)
                            .onChange(of: backgroundColor) { _, newValue in
                                settings.setBackgroundColor(newValue)
                            }

                        ColorPicker("Circle Color", selection: $circleColor)
                            .onChange(of: circleColor) { _, newValue in
                                settings.setCircleColor(newValue)
                            }
                    }

                    Section {
                        Button {
                            showPreview.toggle()
                        } label: {
                            HStack {
                                Image(systemName: "play.circle.fill")
                                Text("Preview Breathing Circle")
                                Spacer()
                            }
                        }
                    }

                    Section {
                        Button {
                            resetToDefaults()
                        } label: {
                            HStack {
                                Image(systemName: "arrow.counterclockwise")
                                Text("Reset to Defaults")
                                Spacer()
                            }
                            .foregroundColor(.red)
                        }
                    }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showPreview) {
                PreviewSheet(settings: settings)
            }
            .onAppear {
                // Load user name from onboarding data
                if let userData = onboardingData.first {
                    userName = userData.userName
                }
            }
            .onDisappear {
                // Auto-save settings when leaving the view
                saveSettings()
            }
        }
    }

    private func saveSettings() {
        // Save breathing settings
        if let encoded = try? JSONEncoder().encode(settings) {
            settingsData = encoded
        }

        // Save user name
        if let userData = onboardingData.first {
            userData.userName = userName
            try? modelContext.save()
        }
    }

    private func resetToDefaults() {
        settings = BreathingSettings()
        backgroundColor = settings.backgroundColor
        circleColor = settings.circleColor
    }
}

struct PreviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    let settings: BreathingSettings

    var body: some View {
        ZStack {
            settings.backgroundColor
                .ignoresSafeArea()

            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding()
                }

                Spacer()

                BreathingCircleView(settings: settings, isActive: true)

                Spacer()

                Text("Preview Mode")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.bottom, 40)
            }
        }
    }
}

#Preview {
    SettingsView()
}
