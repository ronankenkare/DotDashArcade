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
| Contract REQ-012 home / support | dot_dashUITests home and navigation; testSupportMenuKeepsBottomToolbarStationary | No automated external form submission check |

Most evidence above verifies component requirements that refine the listed system requirement; see Verification by level.

## Automated command

From the repository root, run xcodebuild -project dot-dash.xcodeproj -scheme dot-dash -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:dot-dashTests test. Run the dot-dashUITests target separately or use Command-U in Xcode. Check available simulator destinations first. Unit tests use Swift Testing; UI tests use XCTest.

## Manual acceptance

- Exercise both modes: Start, hit, miss, replay, mid-run mode change, Back. Validates NEED-001 and NEED-002.
- Background a live run and return: motion remains stopped until Start resets the run. Repeat while Game Over is visible; it should remain Game Over. Validates NEED-004.
- Verify bests remain separate, never regress, and update Home on return. Check a legacy-only installation. Validates NEED-003.
- Check Light, Dark, System and Increase Contrast on iPhone and iPad. Inspect help button edges and score rows. Validates NEED-005.
- On physical hardware, compare perfect and good haptics. Confirm misses have particle feedback. Validates NEED-005.
- Open and dismiss the Home support menu in portrait and landscape; confirm appearance and support remain aligned in the bottom toolbar. Open Support from Home and confirm external form navigation. Do not submit a form as part of documentation verification. Validates NEED-006.

## Verification by level

Verification follows the V: each level is checked against the level it came from. Test traces are refines traces whose rationale begins "Verifies", because Plus-C has no verifies kind. They record coverage inspected in source, not test results.

| Level | Checked by | Traced coverage |
| --- | --- | --- |
| Stakeholder needs | Manual acceptance below | Validation by review; not automated |
| System requirements | dot_dashUITests flows | 4 of 12: REQ-004, REQ-005, REQ-009, REQ-012 |
| Component requirements | Swift Testing unit suites; two UI layout tests | 18 of 29 |

System requirements without a UI-flow trace are covered only through their component requirements' unit tests and the manual acceptance checks.

| Component requirement | Tests |
| --- | --- |
| Frame step (CMP-001) | None; manual: device frame-timing check |
| Marker advance (CMP-002) | plainAdvanceMovesRightByDirSpeedDt, movingLeftDecreasesPositionSymmetrically, rightEdgeBounceClampsToOneAndFlipsDirection, leftEdgeBounceClampsToZeroAndFlipsDirection, landingExactlyOnOneTriggersBounceBecauseComparisonIsInclusive, overshootIsClampedNotReflected, zeroDtIsNoOp, tenSecondSimulationStaysInBoundsAndBouncesRepeatedly, degenerateHugeStepFromLeftEdgeClampsToRightEdge, degenerateHugeStepFromRightEdgeClampsToLeftEdge |
| Target test (CMP-003) | inZoneAtZoneCenterIsTrue, inZoneJustInsideEdgesIsTrue, inZoneExactlyOnEdgesIsTrue, inZoneJustOutsideEdgesIsFalse, markerAtZeroVersusLeftEdgeZone, markerAtOneVersusRightEdgeZone, tinyZoneStillDetectsCenterHit |
| Perfect band (CMP-004) | inPerfectAtZoneCenterIsTrue, inPerfectOutsideFullZoneIsFalse, inPerfectInsideFullZoneButOutsideInnerIsFalse, inPerfectAtInnerBoundaryIsTrue |
| Mode settings (CMP-005) | perfectHitMultipliesSpeedBySpeedMulPerfect, goodHitMultipliesSpeedBySpeedMulGood, advancedPerfectHitShrinksZoneWidthByPointNine, advancedGoodHitShrinksZoneWidthByPointNineFour, classicHitLeavesZoneWidthUnchanged, advancedRepeatedHitsClampZoneWidthAtMinimum, classicSettingsMatchExpectedConstants, advancedSettingsMatchExpectedConstants |
| Hit update (CMP-006) | inZoneTapScoresAndKeepsGameRunning, perfectHitMultipliesSpeedBySpeedMulPerfect, goodHitMultipliesSpeedBySpeedMulGood, advancedPerfectHitShrinksZoneWidthByPointNine, advancedGoodHitShrinksZoneWidthByPointNineFour, classicHitLeavesZoneWidthUnchanged, advancedRepeatedHitsClampZoneWidthAtMinimum, hitMovesZoneCenterAwayFromPreviousCenter, twelfthHitAdvancesThemeIdxToOne |
| Hit feedback (CMP-007) | None; manual: haptics on physical hardware |
| Miss handling (CMP-008) | gameOverPersistsNewBestClassic, gameOverDoesNotRegressBestClassic, gameOverPersistsNewBestAdvanced |
| Particle bursts (CMP-009) | None; manual: visual particle check |
| Particle update (CMP-010) | updateParticlesAgesMovesAndRemoves |
| Theme thresholds (CMP-011) | twelfthHitAdvancesThemeIdxToOne, pickThemeIndexThresholds |
| Target relocation (CMP-012) | pickNewZoneCenterStaysInBounds, pickNewZoneCenterMovesByMinMove, pickNewZoneCenterHandlesExtremePrevCenter, hitMovesZoneCenterAwayFromPreviousCenter |
| Run reset (CMP-013) | tapWhileNotRunningResetsGame, resetRestoresClassicStartState, resetAppliesAdvancedStartValues |
| Stopped tap (CMP-014) | tapWhileNotRunningResetsGame |
| Mode change (CMP-015) | changeModeToSameModeIsNoOp, changeModeClassicToAdvancedResetsToAdvancedStartState, changeModeMidRunDiscardsTheRun, changeModeAdvancedToClassicAppliesClassicStartValues |
| Pause to instructions (CMP-016) | None; manual: background a live run |
| Display link ownership (CMP-017) | None; manual: lifecycle scenario |
| Best loading and migration (CMP-018) | bestScoresLoadFromUserDefaults, legacyBestScoreMigratesToClassic, legacyMigrationDoesNotOverwriteExistingClassicBest |
| Scene lifecycle (CMP-019) | None; manual: lifecycle scenario |
| Game surface (CMP-020) | None; manual: play both modes |
| Instructions and result (CMP-021) | None; manual: play, miss, replay |
| In-game mode switch (CMP-022) | None; manual: mid-run mode change |
| Score readout (CMP-023) | bestCurrentFollowsMode |
| Appearance cycle (CMP-024) | appearancePreferenceCyclesLightDarkSystem, appearancePreferenceFallsBackToSystemForNewInstalls |
| Navigation and appearance (CMP-025) | appearancePreferenceFallsBackToSystemForNewInstalls, testPlayNavigatesToGame |
| Best refresh (CMP-026) | None; manual: Home best after Back |
| Home controls (CMP-027) | testCornerButtonsStayTheSameSizeAcrossAppearances, testSupportMenuKeepsBottomToolbarStationary |
| Shared mode pill (CMP-028) | testModeToggleFlipsLabel |
| App entry and platform (CMP-029) | None; manual: Xcode build |

## Model verification

Use the installed Plus-C application's model validators and split/merge round trips. The separate plus-c command-line binary on this machine uses a different, older format and cannot validate this application's native project parts. The verification script also re-hashes every traced code part with the Plus-C line hash, fails when a traced symbol moves or its lines change, and requires every requirement and every app class in 07 Software Architecture to reach at least one code part through an implements trace.

## Bottom toolbar regression — October 21, 2026

On October 21, 2026, the simulator build and three focused UI tests passed on iPhone 17 (iOS 27.0): testAppearanceButtonCyclesAndPersists, testCornerButtonsStayTheSameSizeAcrossAppearances, and testSupportMenuKeepsBottomToolbarStationary. The support-menu test checks alignment and unchanged vertical positions before opening, while open, and after dismissal in portrait and landscape. The full test suite was not run. The refreshed Duo Home screenshot was visually inspected; Duo automated tests were stopped during runner startup.
