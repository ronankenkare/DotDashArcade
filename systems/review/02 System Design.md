# Dot Dash system design

## Scope and architecture

Dot Dash is a universal iPhone/iPad reflex game. The deployment target is iOS 26.0. The app entry point in dot-dash/dot_dashApp.swift creates ContentView. ContentView owns NavigationStack, the selected home mode, best-score readout, and the persisted appearance preference. Home's Play selects a navigation destination; it does not start marker motion. HomeView places appearance and a native Support Menu in a horizontal HStack separated by a spacer, anchored with safeAreaInset(edge: .bottom). The system presents the menu outside toolbar layout, so opening it cannot enlarge the row or move the appearance control. The fixed bottom toolbar respects the safe area and stays horizontal on iPhone Duo, where native bottomBar items adapt into a trailing vertical rail in landscape.

GameView owns a MainActor GameState through StateObject. GameState is an ObservableObject publishing score, flags, marker, target and particles. GameBarView renders a SwiftUI Canvas; ScoreBarView, HelpOverlayView and ModeBadgeView observe the same model. ModeTogglePill is shared with Home.

## Timing and rendering

GameView starts CADisplayLink on appear and on active scene phase. startLoop is idempotent; stopLoop invalidates and clears the link. step computes elapsed time and caps it at 50 ms. The marker moves only when running. Flash fades and particles age even when not running. Particle displacement is per frame, not velocity multiplied by dt; this is current behavior.

## Rules and difficulty

| Setting | Classic | Advanced |
| --- | --- | --- |
| Start width | 0.36 | 0.26 |
| Start speed (normalized bar units/s) | 0.55 | 0.80 |
| Perfect fraction | 0.45 | 0.30 |
| Speed multiplier perfect / good | 1.10 / 1.05 | 1.15 / 1.10 |
| Width multiplier perfect / good | 1.00 / 1.00 | 0.90 / 0.94 |
| Minimum width | 0.10 | 0.06 |

Each hit scores one point, regardless of perfect classification. There is no speed cap. Width is clamped between the mode minimum and 0.5 after multiplication. New centers are sampled within 0.15...0.85, with up to 16 attempts at the movement threshold. The target may extend beyond a bar endpoint when wide; its center is what is bounded. Theme thresholds are 12, 25 and 40.

## Local persistence

| Key | Owner | Write trigger |
| --- | --- | --- |
| dotdash_best_classic_v1 | GameState | Classic miss; eligible legacy migration |
| dotdash_best_advanced_v1 | GameState | Advanced miss |
| dotdash_best_v1 | GameState reads | Legacy migration input; not removed |
| dotdash_appearance_v1 | ContentView AppStorage | Appearance button |

Home refreshes bests on appear. GameState loads mode bests during initialization. Quitting, pausing, switching modes, or navigating back during a live run does not save that run as a new best.

## External interfaces

The gameplay path needs no backend. UIKit supplies notification and impact haptics. SwiftUI scenePhase supplies lifecycle events. Support calls UIApplication.open for the Google Form URL in ContentView.swift. Form availability and network behavior are outside the game loop.

## Source map

- dot-dash/dot_dashApp.swift: application scene.
- dot-dash/ContentView.swift: navigation, home, appearance, support and best refresh.
- dot-dash/GameView.swift: game views, GameState, physics, rules, effects and storage.
- dot-dashTests/: Swift Testing suites.
- dot-dashUITests/: XCUITest flows and launch measurements.


## Traceability

Traceability runs one level at a time, and each element traces only to the level directly above it.

| Level | Where | Traces upward |
| --- | --- | --- |
| Stakeholder needs | 00 Stakeholder Needs | Top of the tree |
| System requirements | 01 Requirements | Refine needs; design views 06–17 satisfy them |
| Component requirements | 18 Component Requirements | Derive from system requirements; allocated to 07 architecture classes, which satisfy them |
| Code | Swift symbol parts in project.plc | Implement component requirements; Swift types also implement their 07 class |
| Tests | Swift test functions in project.plc | Verify component requirements (unit tests) or system requirements (UI flows) |

Plus-C has no derives or verifies trace kind, so derivation and verification are recorded as refines traces whose rationale begins "Derived from" or "Verifies". Code never traces to a need or a system requirement; the verification script rejects a trace that skips a level. Each requirements document ends with a trace summary.

Each code part names a Swift symbol and its line range and records the Plus-C line hash, so the code editor marks traced lines and flags edits. The whole-file SHA-256 baselines remain for review of any source change. Line numbers below were inspected on October 28, 2026. Platform services drawn in 07 (CADisplayLink, UserDefaults and the haptic generators) are used by app code but not implemented by it, so they carry no code trace.

| Code part | Lines | Implements |
| --- | --- | --- |
| dot_dashApp.swift · dot_dashApp | 11–17 | dot_dashApp class, CMP-029 |
| ContentView.swift · AppearancePreference | 6–44 | AppearancePreference class, CMP-024 |
| ContentView.swift · ContentView | 46–233 | ContentView class |
| ContentView.swift · ContentView.appearance | 57–59 | CMP-025 |
| ContentView.swift · ContentView.body | 61–87 | CMP-025 |
| ContentView.swift · ContentView.refreshBests | 89–92 | CMP-026 |
| ContentView.swift · ContentView.HomeView | 105–209 | CMP-027 |
| GameView.swift · GameView | 15–71 | GameView class, CMP-019 |
| GameView.swift · ModeTogglePill | 78–99 | ModeTogglePill class, CMP-028 |
| GameView.swift · GameBarView | 104–155 | GameBarView class, CMP-020 |
| GameView.swift · HelpOverlayView | 158–253 | GameReadoutViews class, CMP-021 |
| GameView.swift · ModeBadgeView | 256–268 | GameReadoutViews class, CMP-022 |
| GameView.swift · ScoreBarView | 271–289 | GameReadoutViews class, CMP-023 |
| GameView.swift · GameState | 294–624 | GameState class |
| GameView.swift · GameState.init | 380–388 | CMP-018 |
| GameView.swift · GameState.deinit | 389–389 | CMP-017 |
| GameView.swift · GameState.startLoop | 391–397 | CMP-017 |
| GameView.swift · GameState.stopLoop | 399–402 | CMP-017 |
| GameView.swift · GameState.reset | 404–419 | CMP-013 |
| GameView.swift · GameState.pauseToHelp | 421–423 | CMP-016 |
| GameView.swift · GameState.step | 427–442 | CMP-001 |
| GameView.swift · GameState.advanceMarker | 445–452 | CMP-002 |
| GameView.swift · GameState.updateParticles | 454–461 | CMP-010 |
| GameView.swift · GameState.handleTap | 465–499 | CMP-006, CMP-007, CMP-008, CMP-014 |
| GameView.swift · GameState.currentSettings | 501–526 | CMP-005 |
| GameView.swift · GameState.changeMode | 528–557 | CMP-015 |
| GameView.swift · GameState.inZone | 561–564 | CMP-003 |
| GameView.swift · GameState.inPerfect | 566–570 | CMP-004 |
| GameView.swift · GameState.pickThemeIndex | 574–579 | CMP-011 |
| GameView.swift · GameState.spawnBurst | 588–604 | CMP-009 |
| GameView.swift · GameState.pickNewZoneCenter | 606–623 | CMP-012 |