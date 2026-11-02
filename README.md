# Dot Dash

A minimalist reflex game for iOS and iPadOS. A dot bounces back and forth across a bar — tap the moment it lands inside the target zone. Every hit speeds up the dot, up to a per-mode cap; Advanced mode also shrinks the target zone. One miss ends the run.

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
│   ├── ContentView.swift      # Home screen: play controls, support, persisted appearance
│   ├── GameView.swift         # Game screen + GameState model + shared UI
│   └── Assets.xcassets/       # ClassicMode / AdvancedMode / AccentColor
├── dot-dashTests/             # Swift Testing unit tests
├── dot-dashUITests/           # XCUITest UI tests
└── dot-dash.xcodeproj
```

### GameView.swift at a glance

All game state and rendering live in one file to keep the dependency graph trivial:

- `BestScores` — best-score UserDefaults keys and the legacy single-best migration, shared by Home and `GameState`.
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

The player’s Light, Dark, or System appearance preference is stored under `dotdash_appearance_v1`. New installs follow the system appearance.

### Theme Progression

Four visual themes unlock by score inside a run (0 / 12 / 25 / 40). See `GameState.pickThemeIndex(for:)`.

## App Store Info

App Store listing copy and metadata are kept as dated snapshots in `App_Store_Info/`. The current one is [v2026.11.02](App_Store_Info/v2026.11.02/v2026.11.02.md):

- **App Store name:** Dot Dash Arcade — *Pure Focus. Pure Fun.* (Games › Casual, Age 4+)
- **Support URL:** [Google support form](https://docs.google.com/forms/d/e/1FAIpQLSc363RKRky1eFwkpDa4Eu2jDMwhBiBsOTacm03HsBZbZKctYQ/viewform?usp=dialog) (also opened by the in-app Support button)
- **Privacy Policy URL:** [Google Drive folder](https://drive.google.com/drive/u/0/folders/1C8FPoMXLpXEHZUfzMExzftD3FauxDxUS)
- **App Privacy:** Data Not Collected

When the listing changes, add a new `vYYYY.MM.DD/` folder with its `vYYYY.MM.DD.md` snapshot (and any screenshots) rather than editing an older one.

### Capturing screenshots

`scripts/capture-app-store-screenshots.sh` builds a Debug copy of the app and captures the seven-shot set on each simulator you name (by name or UDID). It defaults to the required 6.9" iPhone and 13" iPad:

```bash
scripts/capture-app-store-screenshots.sh
scripts/capture-app-store-screenshots.sh -v 2026.11.02 -r both "iPhone 17e" "iPad Pro 11-inch (M5)"
```

| Option | Meaning |
|--------|---------|
| `-v VERSION` | Version folder to save into, e.g. `2026.11.02` or `v2026.11.02` (default: today). Created if it doesn't exist. |
| `-r ORIENTATION` | `portrait` (default), `landscape` or `both`. The app is portrait-only on iPhone, so iPhones skip landscape. |
| `-o DIR` | Save somewhere other than `App_Store_Info/vVERSION/screenshots`. |

Each device and orientation gets its own folder: `App_Store_Info/vVERSION/screenshots/<device>/<orientation>/`, for example `ipad-pro-13-inch-m5/landscape/`. The script sets the status bar to 9:41, switches iPads to Full Screen Apps and seeds the best scores through launch arguments. To freeze each game state, it adds the Debug-only hook in `scripts/app-store-screenshots/` for the build and removes it before capturing, so the app source is left as it was. iPads are rotated with a temporary UI test from the same folder, because iPadOS won't let a full-screen app rotate itself and `simctl` has no rotate command. If `GameView.swift` or `ContentView.swift` changes and `staging.patch` stops applying, regenerate the patch. Set `SHOT_DELAY` (in seconds, default 6) on slow machines.

## Plus-C systems library

Open this repository folder in the installed Plus-C app. The root `project.plc` preserves the project identity, and `systems/` contains 12 editable diagrams and seven native documents covering stakeholder needs, system and component requirements, architecture, states, sequences, difficulty, storage, player flows, verification, and maintenance.

Browse [the review library](systems/index.html) for HTML documents and SVG projections of the native diagrams. The native models replace the retired HTML/Mermaid guide. Requirements are layered: 6 stakeholder needs are refined by 12 system requirements, which are refined by 29 component requirements allocated to architecture classes and implemented by traced Swift symbols, with unit and UI tests traced to the level they verify; the verification plan distinguishes inspected test coverage from executed results.

Run `node scripts/verify-plusc.mjs` to validate native models, trace endpoints, source hashes, and project round trips using the installed app. Set `PLUS_C_ASAR` if the app is installed elsewhere. The separate legacy `plus-c` CLI uses an incompatible file format. Four prose documents intentionally produce “No requirements” warnings in the app's requirements-document editor.

Keep native models and their review previews synchronized when editing behavior. See [maintenance guidance](systems/review/05-maintenance-and-risks.html).

The [iPhone Duo UI flow](systems/review/17-iphone-duo-ui.html) uses actual iPhone Duo simulator screenshots of Home, instructions, play and results, with editable navigation hotspots.
