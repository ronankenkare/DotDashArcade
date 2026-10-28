# Dot Dash system requirements

What the app shall do, written at the level a player or tester can observe. Each requirement refines stakeholder needs in 00 Stakeholder Needs and is refined in turn by the component requirements in 18 Component Requirements, which carry the exact values the Swift implements. Source of truth for current behavior: the checked-in Swift source and Xcode project.

## REQ-001 Local reflex play

The app shall run on iPhone and iPad with iOS or iPadOS 26.0 or later and shall provide all gameplay without network access, accounts or third-party runtime services.

## REQ-002 Bounded marker motion

During a run, the marker shall move continuously along the bar at the run's current speed in proportion to elapsed time, and shall reverse direction at each end without leaving the bar.

## REQ-003 Inclusive hit classification

A tap during a run shall count as a hit exactly when the marker is inside the target, edges included, and a hit near the target's center shall be classified as perfect.

## REQ-004 Hit progression

Each hit shall score one point, give success feedback, speed the marker up (more for a perfect hit) and move the target; in Advanced mode each hit shall also narrow the target, down to a minimum width.

## REQ-005 Miss and durable best

A miss shall end the run with failure feedback, show the mode, score and best, and keep the score as that mode's best only if it beats the stored best, leaving the other mode's best unchanged.

## REQ-006 Mode and restart behavior

The player shall be able to start a fresh run from the instructions, from the result screen, or by tapping the stopped game. Choosing a different mode shall abandon the current run, without saving it, and apply that mode's difficulty.

## REQ-007 Lifecycle handling

When the app becomes inactive or moves to the background during a run, the run shall stop and the instructions shall be shown; returning shall not resume it. Leaving the game screen shall stop all game timing.

## REQ-008 Target placement

After each hit, the target shall move to a new position that stays well inside the bar and is, whenever possible, clearly away from its previous position.

## REQ-009 Appearance preference

From Home, the player shall be able to choose Light, Dark or System appearance; the choice shall apply to every screen, persist across launches and default to System.

## REQ-010 Best migration

A best score recorded by an earlier version of the app shall carry forward as the Classic best without replacing a Classic best recorded since.

## REQ-011 Feedback and themes

Hits and misses shall produce visibly different particle bursts, and the game's color theme shall change as the score passes fixed milestones.

## REQ-012 Home and support

Home shall let the player choose a mode, see that mode's best, start play, change appearance and open the external support form.

## Trace summary

| System requirement | Refines needs | Refined by component requirements |
| --- | --- | --- |
| Local reflex play (REQ-001) | NEED-001 | CMP-029 |
| Bounded marker motion (REQ-002) | NEED-002 | CMP-001, CMP-002 |
| Inclusive hit classification (REQ-003) | NEED-002 | CMP-003, CMP-004, CMP-020 |
| Hit progression (REQ-004) | NEED-002, NEED-005 | CMP-005, CMP-006, CMP-007, CMP-009, CMP-023 |
| Miss and durable best (REQ-005) | NEED-002, NEED-003 | CMP-008, CMP-009, CMP-018, CMP-021, CMP-023 |
| Mode and restart behavior (REQ-006) | NEED-001, NEED-002 | CMP-005, CMP-013, CMP-014, CMP-015, CMP-020, CMP-021, CMP-022, CMP-028 |
| Lifecycle handling (REQ-007) | NEED-004 | CMP-016, CMP-017, CMP-019 |
| Target placement (REQ-008) | NEED-002 | CMP-012 |
| Appearance preference (REQ-009) | NEED-005 | CMP-024, CMP-025, CMP-027 |
| Best migration (REQ-010) | NEED-003 | CMP-018 |
| Feedback and themes (REQ-011) | NEED-005 | CMP-001, CMP-009, CMP-010, CMP-011 |
| Home and support (REQ-012) | NEED-001, NEED-003, NEED-006 | CMP-025, CMP-026, CMP-027, CMP-028 |