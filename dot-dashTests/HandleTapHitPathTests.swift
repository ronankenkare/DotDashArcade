//
//  HandleTapHitPathTests.swift
//  dot-dashTests
//
//  Tests for the HIT branch of GameState.handleTap(screenWidth:).
//  The miss/game-over branch is covered in dot_dashTests.swift.
//

import Testing
import UIKit
@testable import dot_dash

@MainActor
@Suite(.serialized)
struct HandleTapHitPathTests {

    private let tolerance: CGFloat = 0.0001

    /// Mode constants mirrored from GameState.currentSettings() so the tests
    /// lock the contract independently of the implementation.
    private func expected(for mode: GameState.Mode)
        -> (startZoneWidth: CGFloat, startSpeed: CGFloat,
            speedMulPerfect: CGFloat, speedMulGood: CGFloat,
            minZoneWidth: CGFloat)
    {
        switch mode {
        case .classic:  return (0.36, 0.55, 1.10, 1.05, 0.10)
        case .advanced: return (0.26, 0.80, 1.15, 1.10, 0.06)
        }
    }

    /// A running game with a deterministic zone: zone spans 0.3...0.7 and the
    /// perfect inner band spans 0.4...0.6. markerPos 0.5 is a perfect hit;
    /// markerPos 0.65 is a good (non-perfect) hit.
    private func makeRunningGame(mode: GameState.Mode, markerPos: CGFloat) -> GameState {
        let g = GameState()
        g.mode = mode
        g.running = true
        g.showHelp = false
        g.gameOver = false
        g.zoneCenter = 0.5
        g.zoneWidth = 0.4
        g.perfectZoneFrac = 0.5
        g.speed = 0.6
        g.markerPos = markerPos
        return g
    }

    // MARK: - Basic hit outcome

    @Test(arguments: [GameState.Mode.classic, GameState.Mode.advanced])
    func inZoneTapScoresAndKeepsGameRunning(mode: GameState.Mode) {
        let g = makeRunningGame(mode: mode, markerPos: 0.5)
        g.handleTap(screenWidth: 320)
        #expect(g.score == 1)
        #expect(g.gameOver == false)
        #expect(g.running == true)
        #expect(g.showHelp == false)
    }

    // MARK: - Speed progression

    @Test(arguments: [GameState.Mode.classic, GameState.Mode.advanced])
    func perfectHitMultipliesSpeedBySpeedMulPerfect(mode: GameState.Mode) {
        let g = makeRunningGame(mode: mode, markerPos: 0.5) // inside 0.4...0.6
        let e = expected(for: mode)
        g.handleTap(screenWidth: 320)
        #expect(abs(g.speed - 0.6 * e.speedMulPerfect) < tolerance)
    }

    @Test(arguments: [GameState.Mode.classic, GameState.Mode.advanced])
    func goodHitMultipliesSpeedBySpeedMulGood(mode: GameState.Mode) {
        let g = makeRunningGame(mode: mode, markerPos: 0.65) // in zone, outside inner band
        let e = expected(for: mode)
        g.handleTap(screenWidth: 320)
        #expect(abs(g.speed - 0.6 * e.speedMulGood) < tolerance)
    }

    // MARK: - Zone width progression

    @Test func advancedPerfectHitShrinksZoneWidthByPointNine() {
        let g = makeRunningGame(mode: .advanced, markerPos: 0.5)
        g.handleTap(screenWidth: 320)
        #expect(abs(g.zoneWidth - 0.4 * 0.90) < tolerance)
    }

    @Test func advancedGoodHitShrinksZoneWidthByPointNineFour() {
        let g = makeRunningGame(mode: .advanced, markerPos: 0.65)
        g.handleTap(screenWidth: 320)
        #expect(abs(g.zoneWidth - 0.4 * 0.94) < tolerance)
    }

    @Test func classicHitLeavesZoneWidthUnchanged() {
        // Perfect hit
        let perfect = makeRunningGame(mode: .classic, markerPos: 0.5)
        perfect.handleTap(screenWidth: 320)
        #expect(abs(perfect.zoneWidth - 0.4) < tolerance)
        // Good (non-perfect) hit
        let good = makeRunningGame(mode: .classic, markerPos: 0.65)
        good.handleTap(screenWidth: 320)
        #expect(abs(good.zoneWidth - 0.4) < tolerance)
    }

    @Test func advancedRepeatedHitsClampZoneWidthAtMinimum() {
        let g = makeRunningGame(mode: .advanced, markerPos: 0.5)
        g.zoneWidth = 0.26 // advanced start width
        let e = expected(for: .advanced)
        for _ in 0..<40 {
            // zoneCenter re-rolls after every hit; aim dead center so each
            // tap is a guaranteed hit (never a miss / game over).
            g.markerPos = g.zoneCenter
            g.handleTap(screenWidth: 320)
            #expect(g.running == true)
            #expect(g.zoneWidth >= e.minZoneWidth - tolerance)
            #expect(g.zoneWidth <= 0.5 + tolerance)
        }
        #expect(abs(g.zoneWidth - e.minZoneWidth) < tolerance)
    }

    // MARK: - Zone center re-roll

    @Test func hitMovesZoneCenterAwayFromPreviousCenter() {
        let g = makeRunningGame(mode: .classic, markerPos: 0.5)
        // Width 0.10 keeps minMove modest (0.15) so the 16-try rejection
        // sampler virtually always satisfies the >= 0.08 movement guarantee.
        g.zoneWidth = 0.10
        let oldCenter = g.zoneCenter
        g.handleTap(screenWidth: 320)
        #expect(g.zoneCenter != oldCenter)
        #expect(abs(g.zoneCenter - oldCenter) >= 0.08)
        #expect(g.zoneCenter >= 0.15)
        #expect(g.zoneCenter <= 0.85)
    }

    // MARK: - Tap while not running

    @Test(arguments: [GameState.Mode.classic, GameState.Mode.advanced])
    func tapWhileNotRunningResetsGame(mode: GameState.Mode) {
        let g = GameState()
        g.mode = mode
        g.running = false
        g.showHelp = true
        g.gameOver = true
        g.score = 5
        g.themeIdx = 2
        let e = expected(for: mode)
        g.handleTap(screenWidth: 320)
        #expect(g.score == 0)
        #expect(g.running == true)
        #expect(g.showHelp == false)
        #expect(g.gameOver == false)
        #expect(g.themeIdx == 0)
        #expect(abs(g.speed - e.startSpeed) < tolerance)
        #expect(abs(g.zoneWidth - e.startZoneWidth) < tolerance)
        #expect(abs(g.zoneCenter - 0.5) < tolerance)
        #expect(g.markerPos >= 0)
        #expect(g.markerPos <= 1)
    }

    // MARK: - Theme progression

    @Test func twelfthHitAdvancesThemeIdxToOne() {
        let g = makeRunningGame(mode: .classic, markerPos: 0.5)
        g.score = 11
        #expect(g.themeIdx == 0)
        g.handleTap(screenWidth: 320)
        #expect(g.score == 12)
        #expect(g.themeIdx == 1)
    }
}
