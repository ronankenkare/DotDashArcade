# Dot Dash component requirements

Contracts derived from the system requirements in 01 Requirements and allocated to the classes in 07 Software Architecture. They hold the exact values and behaviors the Swift implements; code traces implement these requirements, and unit tests verify them.

## GameState: timing and motion

Allocated to GameState.

### CMP-001 Frame step

GameState.step shall take dt as the difference between successive CADisplayLink timestamps, cap it at 0.05 s, fade the flash value, advance the marker only while a run is active, and update particles on every callback.

### CMP-002 Marker advance

advanceMarker shall add direction × speed × dt to the position, clamp the result to 0...1, and reverse direction when the position reaches 0 or 1 inclusive, discarding any excess distance.

## GameState: rules and difficulty

Allocated to GameState.

### CMP-003 Target test

inZone shall be true exactly when zoneCenter − zoneWidth/2 ≤ markerPos ≤ zoneCenter + zoneWidth/2.

### CMP-004 Perfect band

inPerfect shall be true exactly when markerPos lies within zoneCenter ± zoneWidth/2 × perfectZoneFrac, bounds included.

### CMP-005 Mode settings

Classic shall start at width 0.36, speed 0.55 and perfect fraction 0.45, with speed × 1.10 perfect / 1.05 good, width × 1.00 and minimum width 0.10. Advanced shall start at 0.26, 0.80 and 0.30, with speed × 1.15 / 1.10, width × 0.90 / 0.94 and minimum 0.06.

### CMP-006 Hit update

On a hit, handleTap shall add one point, multiply speed and width by the mode's factors for the hit quality, clamp width to the mode minimum ... 0.5, relocate the target and select the theme for the new score. Speed shall have no maximum.

### CMP-007 Hit feedback

A perfect hit shall raise flash by 0.5 and emit a success notification and a rigid impact at intensity 1.0; a good hit shall raise flash by 0.35 and emit a warning notification and an impact at 0.6. Generators shall be prepared again after each hit.

### CMP-008 Miss handling

On a miss, handleTap shall stop the run, set gameOver, store max(best, score) for the current mode under dotdash_best_classic_v1 or dotdash_best_advanced_v1, and show the overlay. It shall not touch the other mode's key.

### CMP-009 Particle bursts

spawnBurst shall emit 18 particles at the marker's screen position, evenly spread in angle with up to 0.2 rad jitter, speed 2–5 for a hit or 1–3 for a miss, and lifetime 0.6–1.0 s.

### CMP-010 Particle update

updateParticles shall advance each particle's age by dt and its position by vx and vy per update, and remove particles whose alpha has reached zero.

### CMP-011 Theme thresholds

pickThemeIndex shall return 0 below 12, 1 from 12, 2 from 25 and 3 from 40.

### CMP-012 Target relocation

pickNewZoneCenter shall sample centers in 0.15...0.85, trying up to 16 times for a move of at least max(0.08, min(0.22, zoneWidth × 0.9 + 0.06)) and otherwise accepting the last candidate.

## GameState: run lifecycle and storage

Allocated to GameState.

### CMP-013 Run reset

reset shall start a run in the current mode with its start speed, width and perfect fraction, a random marker position and direction, a target centered at 0.5, score 0, no particles, no flash and theme 0.

### CMP-014 Stopped tap

handleTap shall call reset whenever no run is active.

### CMP-015 Mode change

changeMode to a different mode shall stop any run, apply that mode's start values and show instructions without a game-over result or saved best. changeMode to the current mode shall do nothing.

### CMP-016 Pause to instructions

pauseToHelp shall stop an active run, show instructions and clear gameOver; it shall do nothing when no run is active.

### CMP-017 Display link ownership

startLoop shall create and schedule one CADisplayLink on the main run loop in common modes only when none exists; stopLoop and deinit shall invalidate it.

### CMP-018 Best loading and migration

GameState shall load both mode bests from their keys at initialization and copy a positive dotdash_best_v1 into dotdash_best_classic_v1 only when the stored Classic best is zero.

## GameView

Allocated to GameView.

### CMP-019 Scene lifecycle

GameView shall apply the initial mode, show instructions and start the display link on appear; stop the link on disappear; pause to instructions and stop the link on inactive or background; and restart only the link on active.

## GameBarView

Allocated to GameBarView.

### CMP-020 Game surface

GameBarView shall draw the bar, target, marker and particles on a Canvas at 40% of its height and forward every tap, with its width, to handleTap.

## Game readouts

Allocated to GameReadoutViews.

### CMP-021 Instructions and result

HelpOverlayView shall show How To Play before a run and Game Over with mode, score and best after a miss, and its Start or Play Again button shall call reset.

### CMP-022 In-game mode switch

ModeBadgeView shall switch between Classic and Advanced through changeMode.

### CMP-023 Score readout

ScoreBarView shall show the current score and the current mode's best (GameState.bestCurrent).

## AppearancePreference

Allocated to AppearancePreference.

### CMP-024 Appearance cycle

AppearancePreference shall cycle Light → Dark → System → Light, map to a light, dark or unforced color scheme, and name its storage key dotdash_appearance_v1.

## ContentView and Home

Allocated to ContentView.

### CMP-025 Navigation and appearance

ContentView shall open GameView in the chosen mode when Play is pressed, read a missing or unknown stored appearance as System, and apply the preference to the whole navigation hierarchy.

### CMP-026 Best refresh

ContentView shall read both mode bests from UserDefaults whenever Home appears.

### CMP-027 Home controls

HomeView shall show the mode pill, the chosen mode's best, Play, and a fixed bottom toolbar whose appearance and Support menu buttons are the same size and stay in place while the menu opens; Support shall open the configured Google Form externally.

## ModeTogglePill

Allocated to ModeTogglePill.

### CMP-028 Shared mode pill

ModeTogglePill shall render the shared "Mode: Classic / Advanced" control and leave the toggle action to its caller.

## dot_dashApp

Allocated to dot_dashApp.

### CMP-029 App entry and platform

dot_dashApp shall present ContentView in a WindowGroup, and the app target shall build with SwiftUI for iOS and iPadOS 26.0 with no third-party dependencies.

## Trace summary

| Component requirement | Refines | Allocated to |
| --- | --- | --- |
| Frame step (CMP-001) | REQ-002, REQ-011 | GameState |
| Marker advance (CMP-002) | REQ-002 | GameState |
| Target test (CMP-003) | REQ-003 | GameState |
| Perfect band (CMP-004) | REQ-003 | GameState |
| Mode settings (CMP-005) | REQ-004, REQ-006 | GameState |
| Hit update (CMP-006) | REQ-004 | GameState |
| Hit feedback (CMP-007) | REQ-004 | GameState |
| Miss handling (CMP-008) | REQ-005 | GameState |
| Particle bursts (CMP-009) | REQ-004, REQ-005, REQ-011 | GameState |
| Particle update (CMP-010) | REQ-011 | GameState |
| Theme thresholds (CMP-011) | REQ-011 | GameState |
| Target relocation (CMP-012) | REQ-008 | GameState |
| Run reset (CMP-013) | REQ-006 | GameState |
| Stopped tap (CMP-014) | REQ-006 | GameState |
| Mode change (CMP-015) | REQ-006 | GameState |
| Pause to instructions (CMP-016) | REQ-007 | GameState |
| Display link ownership (CMP-017) | REQ-007 | GameState |
| Best loading and migration (CMP-018) | REQ-005, REQ-010 | GameState |
| Scene lifecycle (CMP-019) | REQ-007 | GameView |
| Game surface (CMP-020) | REQ-003, REQ-006 | GameBarView |
| Instructions and result (CMP-021) | REQ-005, REQ-006 | GameReadoutViews |
| In-game mode switch (CMP-022) | REQ-006 | GameReadoutViews |
| Score readout (CMP-023) | REQ-004, REQ-005 | GameReadoutViews |
| Appearance cycle (CMP-024) | REQ-009 | AppearancePreference |
| Navigation and appearance (CMP-025) | REQ-009, REQ-012 | ContentView |
| Best refresh (CMP-026) | REQ-012 | ContentView |
| Home controls (CMP-027) | REQ-009, REQ-012 | ContentView |
| Shared mode pill (CMP-028) | REQ-006, REQ-012 | ModeTogglePill |
| App entry and platform (CMP-029) | REQ-001 | dot_dashApp |