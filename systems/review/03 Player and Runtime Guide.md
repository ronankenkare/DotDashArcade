# Player and runtime guide

## Normal run

1. Open the app; Home defaults to Classic and follows the stored appearance or System.
2. Choose Classic or Advanced and tap Play.
3. Read How To Play and tap Start. A fresh run randomizes marker position and direction; target center begins at 0.5.
4. Tap the game surface when the marker is inside the target. Every hit adds one point. Perfect hits increase speed more strongly.
5. A miss shows Game Over, saves the mode best, and displays score, best and mode.
6. Play Again begins a new run in the same mode. Back returns to Home, which refreshes bests.

## Interruptions

Inactive/background pauses a running run to instructions and invalidates CADisplayLink. Foreground resumes display callbacks only. The Start button resets score, position, difficulty, particles and theme; it does not resume the interrupted run. An inactive event on an already stopped game does not replace its existing overlay.

## Changing mode

The in-game mode pill applies the new settings immediately, clears score and effects, and shows instructions. It discards an in-progress run without saving a best. Calling changeMode with the same mode is a no-op. On first Classic entry, this means the pre-Start world may still have GameState's initializer defaults (width 0.32 and speed 0.65); reset applies the Classic start values.

## Appearance and accessibility

The Home appearance control cycles Light, Dark and System, applies to the navigation hierarchy, and persists across relaunch. Appearance and support have 48-point label frames in the fixed bottom toolbar. Opening or dismissing the question-mark menu keeps both controls aligned and stationary in portrait and landscape; select Support to open the external form. Critical controls and readouts have accessibility identifiers consumed by UI tests. HelpOverlay's Start/Play Again fill, glass and content shape share a 12-point corner radius. Increased Contrast adds a dark text shadow on that action button.

## Feedback

Perfect hits emit success notification feedback and rigid impact at intensity 1.0; good hits emit warning notification and rigid impact at 0.6. Misses create failure particles; the miss branch does not call the haptic generators. Each burst has 18 particles with randomized direction and lifetime 0.6...1.0 seconds.
