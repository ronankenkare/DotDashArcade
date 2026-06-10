//
//  GameStateLifecycleTests.swift
//  dot-dashTests
//
//  Tests for GameState lifecycle & secondary logic:
//  reset(), changeMode(), pickThemeIndex, currentSettings,
//  bestCurrent, and particle aging.
//

import Testing
import UIKit
@testable import dot_dash

@MainActor
@Suite(.serialized)
struct GameStateLifecycleTests {

    // MARK: - Helpers

    private func clearBestScoreKeys() {
        let d = UserDefaults.standard
        d.removeObject(forKey: "dotdash_best_classic_v1")
        d.removeObject(forKey: "dotdash_best_advanced_v1")
        d.removeObject(forKey: "dotdash_best_v1")
    }

    // MARK: - reset()

    @Test func resetRestoresClassicStartState() {
        let g = GameState()
        g.mode = .classic
        // Dirty the state thoroughly.
        g.score = 9
        g.gameOver = true
        g.showHelp = true
        g.running = false
        g.themeIdx = 3
        g.flash = 0.7
        g.particles.append(GameState.Particle(x: 1, y: 1, vx: 0, vy: 0, life: 1, age: 0, good: true))
        g.particles.append(GameState.Particle(x: 2, y: 2, vx: 0, vy: 0, life: 1, age: 0, good: false))
        g.zoneCenter = 0.2

        g.reset()

        #expect(g.running == true)
        #expect(g.score == 0)
        #expect(g.gameOver == false)
        #expect(g.showHelp == false)
        #expect(g.themeIdx == 0)
        #expect(g.flash == 0)
        #expect(g.particles.isEmpty)
        #expect(g.zoneCenter == 0.5)
        #expect(g.zoneWidth == 0.36)
        #expect(g.speed == 0.55)
        #expect(g.perfectZoneFrac == 0.45)
        #expect(g.markerPos >= 0 && g.markerPos <= 1)
        #expect(g.markerDir == 1 || g.markerDir == -1)
    }

    @Test func resetAppliesAdvancedStartValues() {
        let g = GameState()
        g.mode = .advanced

        g.reset()

        #expect(g.zoneWidth == 0.26)
        #expect(g.speed == 0.80)
        #expect(g.perfectZoneFrac == 0.30)
    }

    // MARK: - changeMode()

    @Test func changeModeToSameModeIsNoOp() {
        let g = GameState()
        g.mode = .classic
        g.score = 5
        g.running = true

        g.changeMode(.classic)

        #expect(g.score == 5)
        #expect(g.running == true)
    }

    @Test func changeModeClassicToAdvancedResetsToAdvancedStartState() {
        let g = GameState()
        g.mode = .classic
        g.score = 6
        g.themeIdx = 2
        g.particles.append(GameState.Particle(x: 0, y: 0, vx: 0, vy: 0, life: 1, age: 0, good: true))

        g.changeMode(.advanced)

        #expect(g.mode == .advanced)
        #expect(g.score == 0)
        #expect(g.showHelp == true)
        #expect(g.gameOver == false)
        #expect(g.running == false)
        #expect(g.speed == 0.80)
        #expect(g.zoneWidth == 0.26)
        #expect(g.perfectZoneFrac == 0.30)
        #expect(g.themeIdx == 0)
        #expect(g.particles.isEmpty)
    }

    @Test func changeModeMidRunDiscardsTheRun() {
        let g = GameState()
        g.mode = .classic
        g.running = true
        g.score = 7

        g.changeMode(.advanced)

        #expect(g.running == false)
        #expect(g.score == 0)
        #expect(g.showHelp == true)
    }

    @Test func changeModeAdvancedToClassicAppliesClassicStartValues() {
        let g = GameState()
        g.mode = .classic
        g.changeMode(.advanced)

        g.changeMode(.classic)

        #expect(g.mode == .classic)
        #expect(g.speed == 0.55)
        #expect(g.zoneWidth == 0.36)
        #expect(g.perfectZoneFrac == 0.45)
        #expect(g.running == false)
        #expect(g.showHelp == true)
    }

    // MARK: - pickThemeIndex

    @Test(arguments: [
        (0, 0), (11, 0),
        (12, 1), (24, 1),
        (25, 2), (39, 2),
        (40, 3), (1000, 3)
    ])
    func pickThemeIndexThresholds(score: Int, expected: Int) {
        let g = GameState()
        #expect(g.pickThemeIndex(for: score) == expected)
    }

    // MARK: - currentSettings

    @Test func classicSettingsMatchExpectedConstants() {
        let g = GameState()
        g.mode = .classic
        let s = g.currentSettings()
        #expect(s.startZoneWidth == 0.36)
        #expect(s.startSpeed == 0.55)
        #expect(s.perfectZoneFrac == 0.45)
        #expect(s.speedMulPerfect == 1.10)
        #expect(s.speedMulGood == 1.05)
        #expect(s.zoneShrinkPerfect == 1.0)
        #expect(s.zoneShrinkGood == 1.0)
        #expect(s.minZoneWidth == 0.10)
    }

    @Test func advancedSettingsMatchExpectedConstants() {
        let g = GameState()
        g.mode = .advanced
        let s = g.currentSettings()
        #expect(s.startZoneWidth == 0.26)
        #expect(s.startSpeed == 0.80)
        #expect(s.perfectZoneFrac == 0.30)
        #expect(s.speedMulPerfect == 1.15)
        #expect(s.speedMulGood == 1.10)
        #expect(s.zoneShrinkPerfect == 0.90)
        #expect(s.zoneShrinkGood == 0.94)
        #expect(s.minZoneWidth == 0.06)
    }

    // MARK: - bestCurrent

    @Test func bestCurrentFollowsMode() {
        clearBestScoreKeys()
        defer { clearBestScoreKeys() }
        let g = GameState()
        g.bestClassic = 4
        g.bestAdvanced = 9
        g.mode = .classic
        #expect(g.bestCurrent == 4)
        g.mode = .advanced
        #expect(g.bestCurrent == 9)
    }

    // MARK: - updateParticles

    @Test func updateParticlesAgesMovesAndRemoves() {
        let g = GameState()
        g.particles.append(GameState.Particle(x: 0, y: 0, vx: 2, vy: -1, life: 1.0, age: 0, good: true))

        g.updateParticles(0.5)

        #expect(g.particles.count == 1)
        #expect(g.particles[0].x == 2)
        #expect(g.particles[0].y == -1)
        #expect(g.particles[0].age == 0.5)

        // Second step pushes age past life (1.1 > 1.0) → particle removed.
        g.updateParticles(0.6)

        #expect(g.particles.isEmpty)
    }
}
