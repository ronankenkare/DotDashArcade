# Verification and evidence

## Status

Coverage below was inspected in source. It is not a claim that the app tests passed in this documentation task. Native Plus-C file round trips, model validators, preview generation and documentation checks are recorded separately in systems/review/validation.json.

| Contract | Existing evidence | Limits |
| --- | --- | --- |
| Contract REQ-001 local app | Xcode project and app source | Device/platform build not run in this task |
| Contract REQ-002 movement | MarkerPhysicsTests | Display callback timing and dt cap need runtime check |
| Contract REQ-003 classification | InZoneTests and dot_dashTests | Haptic perception is manual |
| Contract REQ-004 progression | HandleTapHitPathTests; GameStateLifecycleTests | Visual particles and physical haptics need device check |
| Contract REQ-005 miss / best | dot_dashTests | Persistence assertions mutate shared UserDefaults |
| Contract REQ-006 reset / modes | GameStateLifecycleTests; dot_dashUITests | UI outcomes involving motion are nondeterministic |
| Contract REQ-007 lifecycle | GameView source; manual scenario below | No dedicated scenePhase integration test found |
| Contract REQ-008 placement | dot_dashTests bounded and statistical samples | Minimum movement is best effort, not guaranteed |
| Contract REQ-009 appearance | dot_dashTests; testAppearanceButtonCyclesAndPersists | Visual contrast still needs inspection |
| Contract REQ-010 migration | dot_dashTests legacy cases | Home reads before GameState first initializes |
| Contract REQ-011 effects / themes | GameStateLifecycleTests | Frame-rate dependence and colors need runtime inspection |
| Contract REQ-012 home / support | dot_dashUITests home and navigation | No automated external form submission check |

## Automated command

From the repository root, run xcodebuild -project dot-dash.xcodeproj -scheme dot-dash -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:dot-dashTests test. Run the dot-dashUITests target separately or use Command-U in Xcode. Check available simulator destinations first. Unit tests use Swift Testing; UI tests use XCTest.

## Manual acceptance

- Exercise both modes: Start, hit, miss, replay, mid-run mode change, Back.
- Background a live run and return: motion remains stopped until Start resets the run. Repeat while Game Over is visible; it should remain Game Over.
- Verify bests remain separate, never regress, and update Home on return. Check a legacy-only installation.
- Check Light, Dark, System and Increase Contrast on iPhone and iPad. Inspect help button edges and score rows.
- On physical hardware, compare perfect and good haptics. Confirm misses have particle feedback.
- Open Support from Home and confirm external form navigation. Do not submit a form as part of documentation verification.

## Model verification

Use the installed Plus-C application's model validators and split/merge round trips. The separate plus-c command-line binary on this machine uses a different, older format and cannot validate this application's native project parts.
