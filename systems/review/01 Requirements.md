# Dot Dash requirements

These are reconstructed contracts for the current implementation, not new feature requests. Source of truth: the checked-in Swift source and Xcode project.

## REQ-001 Local reflex play

The app shall present a device-local reflex game on iOS and iPadOS 26.0 or later using SwiftUI and no third-party runtime dependencies.

## REQ-002 Bounded marker motion

Each active display frame shall advance marker position by direction × speed × dt, cap dt at 0.05 seconds, clamp position at 0 or 1, and reverse direction at inclusive endpoints. Excess distance is discarded.

## REQ-003 Inclusive hit classification

A tap during a run shall count as a hit when zoneCenter − zoneWidth/2 ≤ markerPos ≤ zoneCenter + zoneWidth/2. Perfect classification shall use the inclusive inner band with half-width zoneWidth/2 × perfectZoneFrac.

## REQ-004 Hit progression

Every hit shall add one point, emit haptics and 18 good particles, multiply speed and target width by mode and hit quality, relocate the target, and select the score theme. Classic width shall remain unchanged.

## REQ-005 Miss and durable best

A miss shall emit 18 failure particles, stop the run, show Game Over, and persist max(previous best, score) under the current mode key without changing the other mode best.

## REQ-006 Mode and restart behavior

Start, Play Again, or a non-running game-bar tap shall reset the run. Changing to a different mode shall discard the run, apply new settings, and show instructions. Selecting the same mode shall do nothing.

## REQ-007 Lifecycle handling

Entering inactive or background while running shall stop marker motion, show instructions, and stop the display link. Returning active shall restart only the display link; Start begins a fresh run. Leaving GameView shall invalidate the link.

## REQ-008 Target placement

After a hit, zoneCenter shall lie in 0.15...0.85. Relocation shall attempt up to 16 random candidates for movement ≥ max(0.08, min(0.22, zoneWidth × 0.9 + 0.06)), accepting the final candidate if the threshold is not met.

## REQ-009 Appearance preference

Home shall cycle Light → Dark → System → Light, persist the choice under dotdash_appearance_v1, and use System when the value is missing or invalid.

## REQ-010 Best migration

GameState initialization shall copy a positive legacy dotdash_best_v1 to dotdash_best_classic_v1 only when the stored Classic value is zero.

## REQ-011 Feedback and themes

A run shall use theme indices 0/1/2/3 at score thresholds 0/12/25/40. Particle age shall advance with dt while x/y advance by vx/vy per update, including while the run is stopped and the display link is active.

## REQ-012 Home and support

Home shall expose mode selection, the selected best, Play, appearance, and support. Play shall navigate to instructions. Support shall open the configured Google Form externally.
