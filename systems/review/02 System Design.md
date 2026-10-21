# Dot Dash system design

## Scope and architecture

Dot Dash is a universal iPhone/iPad reflex game. The deployment target is iOS 26.0. The app entry point in dot-dash/dot_dashApp.swift creates ContentView. ContentView owns NavigationStack, the selected home mode, best-score readout, and the persisted appearance preference. Home's Play selects a navigation destination; it does not start marker motion.

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
