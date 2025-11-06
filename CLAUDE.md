# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Vipassanā is a native iOS meditation application built with SwiftUI and SwiftData. The app provides guided breathing meditation sessions with customizable durations (15, 30, 45, and 60 minutes) and visual breathing circle animations. Users can customize the appearance and breathing rhythm to match their meditation preferences.

## Development Commands

### Building
```bash
# Build the project
xcodebuild -project Vipasana.xcodeproj -scheme Vipasana -configuration Debug build

# Build for release
xcodebuild -project Vipasana.xcodeproj -scheme Vipasana -configuration Release build
```

### Testing
```bash
# Run unit tests
xcodebuild test -project Vipasana.xcodeproj -scheme Vipasana -destination 'platform=iOS Simulator,name=iPhone 15'

# Run unit tests only (VipasanaTests target)
xcodebuild test -project Vipasana.xcodeproj -scheme Vipasana -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:VipasanaTests

# Run UI tests only (VipasanaUITests target)
xcodebuild test -project Vipasana.xcodeproj -scheme Vipasana -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:VipasanaUITests

# Run a specific test
xcodebuild test -project Vipasana.xcodeproj -scheme Vipasana -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:VipasanaTests/VipasanaTests/example
```

## Architecture

### Data Layer
The app uses **SwiftData** for persistence, configured in `VipasanaApp.swift`:
- `ModelContainer` is set up with a `Schema` containing all data models
- The container is injected into the SwiftUI environment via `.modelContainer()` modifier
- Data models use the `@Model` macro and are stored persistently by default

### Data Models
Data models are defined as classes with the `@Model` macro from SwiftData:
- **MeditationSession** (`Models/MeditationSession.swift`): Tracks meditation sessions with start time, duration, completion status, and session type
- **BreathingSettings** (`Models/BreathingSettings.swift`): Stores user preferences for breathing animation (colors, inhale/exhale duration) using hex color encoding for persistence

### View Layer
The app follows SwiftUI's declarative view architecture with the following key views:

- **HomeView** (`Views/HomeView.swift`): Main landing screen with duration selection cards and session history
- **MeditationSessionView** (`Views/MeditationSessionView.swift`): Active meditation session with timer, breathing circle, and playback controls
- **BreathingCircleView** (`Views/BreathingCircleView.swift`): Animated pulsing circle that syncs with inhale/exhale rhythm
- **SettingsView** (`Views/SettingsView.swift`): Customization interface for colors and breathing timing

Views use `@Query` property wrapper to fetch SwiftData models reactively and access `ModelContext` via `@Environment(\.modelContext)` for CRUD operations. Settings are persisted using `@AppStorage` with JSON encoding.

### App Entry Point
`VipasanaApp.swift` serves as the app's entry point:
- Uses `@main` attribute to designate the app struct
- Initializes the `ModelContainer` with the data schema
- Sets up the root `WindowGroup` scene with the model container

### Testing Structure
- **Unit Tests** (`VipasanaTests/`): Uses Swift Testing framework with `@Test` macro
- **UI Tests** (`VipasanaUITests/`): Uses XCTest framework with `XCTestCase` subclasses for testing UI interactions

## Code Organization

```
Vipasana/
├── Vipasana/                         # Main app target
│   ├── VipasanaApp.swift            # App entry point with SwiftData setup
│   ├── Models/                       # SwiftData models and settings
│   │   ├── MeditationSession.swift  # Session tracking model
│   │   └── BreathingSettings.swift  # User preferences with hex color support
│   ├── Views/                        # SwiftUI views
│   │   ├── HomeView.swift           # Duration selection and history
│   │   ├── MeditationSessionView.swift # Active meditation timer
│   │   ├── BreathingCircleView.swift   # Animated breathing guide
│   │   └── SettingsView.swift       # Customization interface
│   └── Assets.xcassets/             # App assets (icons, colors, images)
├── VipasanaTests/                    # Unit tests using Swift Testing
└── VipasanaUITests/                  # UI tests using XCTest
```

## Key Features

### Meditation Sessions
- Four preset durations: 15, 30, 45, and 60 minutes
- Real-time countdown timer with progress bar
- Pause/resume and stop controls during active sessions
- Session history tracking with completion status

### Breathing Animation
- Customizable pulsing circle that scales with inhale/exhale rhythm
- Adjustable breath timing (2-10 seconds for inhale/exhale independently)
- Default Vipassanā rhythm: 4s inhale, 6s exhale
- Visual feedback with "Breathe In" / "Breathe Out" text

### Customization
- User-selectable background and circle colors via ColorPicker
- Live preview of breathing animation with custom settings
- Settings persisted using AppStorage and JSON encoding
- Reset to defaults option

## Platform Support
The codebase includes conditional compilation for both iOS and macOS platforms, enabling code sharing across Apple platforms while allowing platform-specific UI customizations.
- always deploy to the current running simulator