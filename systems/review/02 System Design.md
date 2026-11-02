# Dot Dash system design

## Scope and architecture

Dot Dash is a universal iPhone/iPad reflex game. The deployment target is iOS 26.0. The app entry point in dot-dash/dot_dashApp.swift creates ContentView. ContentView owns NavigationStack, the selected home mode, best-score readout, and the persisted appearance preference. Home's Play selects a navigation destination; it does not start marker motion. HomeView places appearance and a native Support Menu in a horizontal HStack separated by a spacer, anchored with safeAreaInset(edge: .bottom). The system presents the menu outside toolbar layout, so opening it cannot enlarge the row or move the appearance control. The fixed bottom toolbar respects the safe area and stays horizontal on iPhone Duo, where native bottomBar items adapt into a trailing vertical rail in landscape.

GameView owns a MainActor GameState through StateObject. Home and GameView share GameState.Mode for the chosen mode. GameState is an ObservableObject publishing score, flags, marker, target and particles. GameBarView renders a SwiftUI Canvas; ScoreBarView, HelpOverlayView and ModeBadgeView observe the same model. ModeTogglePill is shared with Home.

## Timing and rendering

GameView starts CADisplayLink on appear and on active scene phase. startLoop is idempotent; stopLoop invalidates and clears the link. step computes elapsed time and caps it at 50 ms. The marker moves only when running; particles age even when not running. Particle velocities are points per 60 Hz frame and are scaled by dt × 60, so bursts travel the same distance at any refresh rate. updateParticles returns early when there are no particles, so an idle frame publishes nothing. Once no run is active and no particles remain, step pauses the display link; reset resumes it with a fresh timestamp.

## Rules and difficulty

| Setting | Classic | Advanced |
| --- | --- | --- |
| Start width | 0.36 | 0.26 |
| Start speed (normalized bar units/s) | 0.55 | 0.80 |
| Perfect fraction | 0.45 | 0.30 |
| Speed multiplier perfect / good | 1.10 / 1.05 | 1.15 / 1.10 |
| Width multiplier perfect / good | 1.00 / 1.00 | 0.90 / 0.94 |
| Minimum width | 0.10 | 0.06 |
| Maximum speed | 3.0 | 1.8 |

Each hit scores one point, regardless of perfect classification. Speed is capped at the mode maximum, which keeps a 60 Hz frame step at most half the minimum width, so the marker is drawn inside even the narrowest target on every pass. Width is clamped between the mode minimum and 0.5 after multiplication. New centers are sampled within 0.15...0.85, with up to 16 attempts at the movement threshold. The target may extend beyond a bar endpoint when wide; its center is what is bounded. GameBarView clips the drawn target at both bar ends, so the highlight covers exactly the range inZone accepts. The bar reacts at touch-down, not lift-off, so the marker position is sampled when the finger lands. After a miss, taps on the bar are ignored; only Play Again starts a new run. Theme thresholds are 12, 25 and 40.

## Local persistence

| Key | Owner | Write trigger |
| --- | --- | --- |
| dotdash_best_classic_v1 | GameState; BestScores | Classic miss; eligible legacy migration |
| dotdash_best_advanced_v1 | GameState | Advanced miss |
| dotdash_best_v1 | BestScores reads | Legacy migration input; not removed |
| dotdash_appearance_v1 | ContentView AppStorage | Appearance button |

BestScores in GameView.swift owns the best-score keys and the legacy migration. Home refreshes bests on appear through BestScores.load, so a migrated legacy best shows before any game is opened. GameState loads its bests through the same call during initialization, from an injected UserDefaults that defaults to standard; unit tests pass a throwaway suite. Quitting, pausing, switching modes, or navigating back during a live run does not save that run as a new best.

## External interfaces

The gameplay path needs no backend. UIKit supplies notification and impact haptics. SwiftUI scenePhase supplies lifecycle events. Support calls UIApplication.open for the Google Form URL in ContentView.swift. Form availability and network behavior are outside the game loop.

## Source map

- dot-dash/dot_dashApp.swift: application scene.
- dot-dash/ContentView.swift: navigation, home, appearance, support and best refresh.
- dot-dash/GameView.swift: game views, BestScores, GameState, physics, rules, effects and storage.
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

Each code part names a Swift symbol and its line range and records the Plus-C line hash, so the code editor marks traced lines and flags edits. The whole-file SHA-256 baselines remain for review of any source change. Line numbers below were re-anchored on November 2, 2026. Platform services drawn in 07 (CADisplayLink, UserDefaults and the haptic generators) are used by app code but not implemented by it, so they carry no code trace.

| Code part | Lines | Implements |
| --- | --- | --- |
| dot_dashApp.swift · dot_dashApp | 11–17 | dot_dashApp class, CMP-029 |
| ContentView.swift · AppearancePreference | 6–44 | AppearancePreference class, CMP-024 |
| ContentView.swift · ContentView | 46–225 | ContentView class |
| ContentView.swift · ContentView.appearance | 55–57 | CMP-025 |
| ContentView.swift · ContentView.body | 59–80 | CMP-025 |
| ContentView.swift · ContentView.refreshBests | 82–84 | CMP-026 |
| ContentView.swift · ContentView.HomeView | 97–201 | CMP-027 |
| GameView.swift · GameView | 15–71 | GameView class, CMP-019 |
| GameView.swift · ModeTogglePill | 78–99 | ModeTogglePill class, CMP-028 |
| GameView.swift · GameBarView | 104–159 | GameBarView class, CMP-020 |
| GameView.swift · HelpOverlayView | 162–257 | GameReadoutViews class, CMP-021 |
| GameView.swift · ModeBadgeView | 260–272 | GameReadoutViews class, CMP-022 |
| GameView.swift · ScoreBarView | 275–293 | GameReadoutViews class, CMP-023 |
| GameView.swift · BestScores | 299–316 | BestScores class |
| GameView.swift · BestScores.load | 309–315 | CMP-018, CMP-026 |
| GameView.swift · GameState | 321–647 | GameState class |
| GameView.swift · GameState.init | 408–412 | CMP-018 |
| GameView.swift · GameState.deinit | 413–413 | CMP-017 |
| GameView.swift · GameState.startLoop | 415–421 | CMP-017 |
| GameView.swift · GameState.stopLoop | 423–426 | CMP-017 |
| GameView.swift · GameState.wakeLoop | 429–433 | CMP-013, CMP-017 |
| GameView.swift · GameState.reset | 435–440 | CMP-013 |
| GameView.swift · GameState.applyStartState | 443–455 | CMP-013, CMP-015 |
| GameView.swift · GameState.pauseToHelp | 457–459 | CMP-016 |
| GameView.swift · GameState.step | 463–476 | CMP-001 |
| GameView.swift · GameState.advanceMarker | 479–486 | CMP-002 |
| GameView.swift · GameState.updateParticles | 490–500 | CMP-010 |
| GameView.swift · GameState.handleTap | 504–541 | CMP-006, CMP-007, CMP-008, CMP-014 |
| GameView.swift · GameState.currentSettings | 543–570 | CMP-005 |
| GameView.swift · GameState.changeMode | 572–580 | CMP-015 |
| GameView.swift · GameState.inZone | 584–587 | CMP-003 |
| GameView.swift · GameState.inPerfect | 589–593 | CMP-004 |
| GameView.swift · GameState.pickThemeIndex | 597–602 | CMP-011 |
| GameView.swift · GameState.spawnBurst | 611–627 | CMP-009 |
| GameView.swift · GameState.pickNewZoneCenter | 629–646 | CMP-012 |