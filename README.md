# Dot Dash

A minimalist reflex game for iOS and iPadOS. A dot bounces back and forth across a bar — tap the moment it lands inside the target zone. Every hit shrinks the zone and speeds up the dot. One miss ends the run.

- **Platform:** iOS / iPadOS 26.0+ (iPhone + iPad, universal)
- **Stack:** SwiftUI, UIKit (haptics), `CADisplayLink` for the game loop
- **Language:** Swift 5
- **Current version:** 1.2.1
- **Bundle ID:** `ronankenkare.dot-dash`

## Getting Started

1. Clone the repo.
2. Open `dot-dash.xcodeproj` in Xcode 26 (or newer).
3. Select the `dot-dash` scheme and an iPhone / iPad simulator (or a connected device).
4. Press **⌘R** to run.

No package managers, no external dependencies.

## Running the Tests

Unit tests use [Swift Testing](https://developer.apple.com/documentation/testing) (`import Testing`) and cover hit-detection, zone placement, and best-score persistence.

```bash
xcodebuild \
  -project dot-dash.xcodeproj \
  -scheme dot-dash \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:dot-dashTests \
  test
```

Or press **⌘U** in Xcode.

UI tests live alongside in `dot-dashUITests/`.

## Project Structure

```
dot-dash/
├── dot-dash/                  # App source
│   ├── dot_dashApp.swift      # @main entry point
│   ├── ContentView.swift      # Home screen: title, mode toggle, best score, Play
│   ├── GameView.swift         # Game screen + GameState model + shared UI
│   └── Assets.xcassets/       # ClassicMode / AdvancedMode / AccentColor
├── dot-dashTests/             # Swift Testing unit tests
├── dot-dashUITests/           # XCUITest UI tests
└── dot-dash.xcodeproj
```

### GameView.swift at a glance

All game state and rendering live in one file to keep the dependency graph trivial:

- `GameState` (`@MainActor ObservableObject`) — marker position, zone, score, mode, particles, haptics, best-score persistence, and the `CADisplayLink` loop (`startLoop` / `stopLoop` / `step`).
- `GameBarView` — `Canvas`-based bar, zone, marker, and particle burst rendering.
- `HelpOverlayView` — how-to-play and game-over card.
- `ModeBadgeView` — bottom-screen mode toggle.
- `ScoreBarView` — top score/best readout.
- `ModeTogglePill` — shared capsule button used by both the home screen and gameplay.

### Game Modes

| Mode      | Start zone | Start speed | Perfect-zone frac | Shrink per hit | Min zone |
| --------- | ---------- | ----------- | ----------------- | -------------- | -------- |
| Classic   | 0.36       | 0.55        | 0.45              | 1.00           | 0.10     |
| Advanced  | 0.26       | 0.80        | 0.30              | 0.90–0.94      | 0.06     |

Tuning lives in `GameState.currentSettings()` in `GameView.swift`.

### Persistence

Best scores are stored in `UserDefaults.standard` under:

- `dotdash_best_classic_v1`
- `dotdash_best_advanced_v1`
- `dotdash_best_v1` *(legacy key; migrated into the classic key on first launch)*

### Theme Progression

Four visual themes unlock by score inside a run (0 / 12 / 25 / 40). See `GameState.pickThemeIndex(for:)`.

