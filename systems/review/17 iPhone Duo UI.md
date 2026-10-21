# iPhone Duo screenshot UI diagram

The four native Plus-C frames contain **actual, unmodified screenshots of Dot Dash running on the iPhone Duo simulator**: Home, How To Play, Running, and Game Over. The previous source-based wireframes have been replaced. Transparent hotspots preserve Play, Start, the miss/results path, Play Again, and Back navigation.

## Capture evidence

- Device: iPhone Duo, iOS 27.1; simulator 69F9029D-6797-4777-9D1B-557F577662B4.
- Display: LCD, screenID 1. PNGs are 1398 × 2034 pixels, shown at 466 × 678 logical points (3× scale).
- Date: October 21, 2026. Appearance: the simulator's current Dark/System rendering; Classic mode.
- App: built from the app source present for the capture build with the dot-dash scheme, Debug, signing disabled for the simulator.
- State navigation: a temporary XCUITest exercised Home → Play → instructions → Start → running → miss → Game Over. The successful capture run passed. The temporary capture test was removed afterward; the capture workflow did not modify the app source or normal test files.
- Capture method: direct simctl screenshot --display=1 at each confirmed state. XCTest's screenshot API returned the inactive display, so those blank images were discarded. An initial coordinate-based attempt did not reach Game Over; the successful run tapped the score-label position on the game surface.

These captures use the outer LCD display in its observed portrait orientation; they do not verify the expanded inner display. App source was being edited concurrently, so the images are timestamped observations of the capture build.

The original PNGs, timestamps, pixel dimensions and SHA-256 hashes are recorded in [the screenshot manifest](../assets/iphone-duo/manifest.json). The score, marker, system chrome and colors are exactly what the simulator rendered; none were replaced with drawn controls.

## Prototype limits

The links illustrate navigation; they do not execute physics, scoring or persistence. A click in the Running hotspot follows the miss path rather than classifying marker position. Mode and appearance changes and external support are not simulated. The image layers and hotspots are editable in Plus-C; the controls inside the screenshots remain raster pixels.

The focused screenshot flow passed. This does not assert that the complete unit/UI regression suite passed or that unrelated device modes were tested.
