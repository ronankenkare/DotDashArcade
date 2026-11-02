//
//  dot_dashTests.swift
//  dot-dashTests
//
//  Created by Ronan Kenkare on 8/8/25.
//

import Testing
import UIKit
@testable import dot_dash

@MainActor
@Suite(.serialized)
struct dot_dashTests {

    // MARK: - Appearance preference

    @Test func appearancePreferenceCyclesLightDarkSystem() {
        #expect(AppearancePreference.light.next == .dark)
        #expect(AppearancePreference.dark.next == .system)
        #expect(AppearancePreference.system.next == .light)
    }

    @Test func appearancePreferenceFallsBackToSystemForNewInstalls() {
        let storedValue: String? = nil
        let preference = storedValue.flatMap(AppearancePreference.init(rawValue:)) ?? .system
        #expect(preference == .system)
        #expect(preference.colorScheme == nil)
    }

    // MARK: - inPerfect (perfect-zone hit detection)

    @Test func inPerfectAtZoneCenterIsTrue() {
        let g = GameState()
        g.zoneCenter = 0.5
        g.zoneWidth = 0.4
        g.perfectZoneFrac = 0.5
        #expect(g.inPerfect(0.5) == true)
    }

    @Test func inPerfectOutsideFullZoneIsFalse() {
        let g = GameState()
        g.zoneCenter = 0.5
        g.zoneWidth = 0.4   // zone spans 0.3...0.7
        g.perfectZoneFrac = 0.5
        #expect(g.inPerfect(0.1) == false)
        #expect(g.inPerfect(0.9) == false)
    }

    @Test func inPerfectInsideFullZoneButOutsideInnerIsFalse() {
        let g = GameState()
        g.zoneCenter = 0.5
        g.zoneWidth = 0.4    // half = 0.2  → zone  0.3...0.7
        g.perfectZoneFrac = 0.5  // inner = 0.1 → inner 0.4...0.6
        #expect(g.inPerfect(0.35) == false)
        #expect(g.inPerfect(0.65) == false)
    }

    @Test func inPerfectAtInnerBoundaryIsTrue() {
        let g = GameState()
        g.zoneCenter = 0.5
        g.zoneWidth = 0.4
        g.perfectZoneFrac = 0.5
        // inner boundary = zoneCenter ± (half * frac) = 0.5 ± 0.1
        #expect(g.inPerfect(0.4) == true)
        #expect(g.inPerfect(0.6) == true)
    }

    // MARK: - pickNewZoneCenter

    @Test func pickNewZoneCenterStaysInBounds() {
        let g = GameState()
        for _ in 0..<200 {
            let prev = CGFloat.random(in: 0.15...0.85)
            let w = CGFloat.random(in: 0.06...0.40)
            let c = g.pickNewZoneCenter(prevCenter: prev, zoneWidth: w)
            #expect(c >= 0.15)
            #expect(c <= 0.85)
        }
    }

    @Test func pickNewZoneCenterMovesByMinMove() {
        let g = GameState()
        // With zoneWidth = 0.1, minMove = max(0.08, min(0.22, 0.1*0.9 + 0.06)) = 0.15.
        // Over [0.15, 0.85] the 16-try rejection sampler virtually always finds a valid
        // candidate; we allow a tiny slack for the rare fallback case.
        var satisfied = 0
        let trials = 200
        for _ in 0..<trials {
            let prev: CGFloat = 0.5
            let c = g.pickNewZoneCenter(prevCenter: prev, zoneWidth: 0.1)
            if abs(c - prev) >= 0.15 { satisfied += 1 }
        }
        #expect(satisfied >= Int(Double(trials) * 0.95))
    }

    @Test func pickNewZoneCenterHandlesExtremePrevCenter() {
        let g = GameState()
        // Previous center pinned near an edge — output must still respect bounds.
        for prev: CGFloat in [0.15, 0.85] {
            for _ in 0..<50 {
                let c = g.pickNewZoneCenter(prevCenter: prev, zoneWidth: 0.2)
                #expect(c >= 0.15)
                #expect(c <= 0.85)
            }
        }
    }

    // MARK: - Best-score persistence

    /// A throwaway defaults domain per test, so suites running in parallel never
    /// share best-score keys and the real app's bests are never touched.
    private func makeDefaults() -> UserDefaults {
        let name = "dotdash-tests-\(UUID().uuidString)"
        let d = UserDefaults(suiteName: name)!
        d.removePersistentDomain(forName: name)
        return d
    }

    /// A running game whose marker is clearly outside the zone (0.15...0.25).
    private func makeMissingGame(mode: GameState.Mode, score: Int, defaults: UserDefaults) -> GameState {
        let g = GameState(defaults: defaults)
        g.mode = mode
        g.running = true
        g.score = score
        g.zoneCenter = 0.2
        g.zoneWidth = 0.1
        g.markerPos = 0.9
        return g
    }

    @Test func bestScoresLoadFromUserDefaults() {
        let d = makeDefaults()
        d.set(7, forKey: BestScores.classicKey)
        d.set(12, forKey: BestScores.advancedKey)
        let g = GameState(defaults: d)
        #expect(g.bestClassic == 7)
        #expect(g.bestAdvanced == 12)
    }

    @Test func legacyBestScoreMigratesToClassic() {
        let d = makeDefaults()
        d.set(9, forKey: BestScores.legacyKey)
        let g = GameState(defaults: d)
        #expect(g.bestClassic == 9)
        #expect(d.integer(forKey: BestScores.classicKey) == 9)
    }

    @Test func homeScreenLoadSeesMigratedLegacyBest() {
        // ContentView reads bests through BestScores.load without creating a GameState.
        let d = makeDefaults()
        d.set(15, forKey: BestScores.legacyKey)
        let bests = BestScores.load(from: d)
        #expect(bests.classic == 15)
        #expect(bests.advanced == 0)
    }

    @Test func legacyMigrationDoesNotOverwriteExistingClassicBest() {
        let d = makeDefaults()
        d.set(9, forKey: BestScores.legacyKey)
        d.set(20, forKey: BestScores.classicKey)
        let g = GameState(defaults: d)
        #expect(g.bestClassic == 20)
    }

    @Test func gameOverPersistsNewBestClassic() {
        let d = makeDefaults()
        d.set(2, forKey: BestScores.classicKey)
        let g = makeMissingGame(mode: .classic, score: 5, defaults: d)
        g.handleTap(screenWidth: 320)
        #expect(g.gameOver == true)
        #expect(g.bestClassic == 5)
        #expect(d.integer(forKey: BestScores.classicKey) == 5)
    }

    @Test func gameOverDoesNotRegressBestClassic() {
        let d = makeDefaults()
        d.set(10, forKey: BestScores.classicKey)
        let g = makeMissingGame(mode: .classic, score: 3, defaults: d)
        g.handleTap(screenWidth: 320)
        #expect(g.bestClassic == 10)
        #expect(d.integer(forKey: BestScores.classicKey) == 10)
    }

    @Test func gameOverPersistsNewBestAdvanced() {
        let d = makeDefaults()
        let g = makeMissingGame(mode: .advanced, score: 8, defaults: d)
        g.handleTap(screenWidth: 320)
        #expect(g.bestAdvanced == 8)
        #expect(d.integer(forKey: BestScores.advancedKey) == 8)
        // Classic must not be touched by an advanced-mode miss.
        #expect(d.integer(forKey: BestScores.classicKey) == 0)
    }

    @Test func pauseToHelpPersistsRunningScoreAsBest() {
        let d = makeDefaults()
        d.set(20, forKey: BestScores.classicKey)
        let g = GameState(defaults: d)
        g.mode = .classic
        g.running = true
        g.score = 30
        g.pauseToHelp()
        #expect(g.running == false)
        #expect(g.showHelp == true)
        #expect(g.gameOver == false)
        #expect(g.bestClassic == 30)
        #expect(d.integer(forKey: BestScores.classicKey) == 30)
    }

    @Test func tapAfterMissKeepsGameOverCard() {
        let g = makeMissingGame(mode: .classic, score: 4, defaults: makeDefaults())
        g.handleTap(screenWidth: 320)   // miss → game over
        g.handleTap(screenWidth: 320)   // follow-up tap on the bar
        #expect(g.gameOver == true)
        #expect(g.running == false)
        #expect(g.showHelp == true)
        #expect(g.score == 4)
    }
}
