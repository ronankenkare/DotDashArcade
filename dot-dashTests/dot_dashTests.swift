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

    private func clearBestScoreKeys() {
        let d = UserDefaults.standard
        d.removeObject(forKey: "dotdash_best_classic_v1")
        d.removeObject(forKey: "dotdash_best_advanced_v1")
        d.removeObject(forKey: "dotdash_best_v1")
    }

    @Test func bestScoresLoadFromUserDefaults() {
        clearBestScoreKeys()
        defer { clearBestScoreKeys() }
        UserDefaults.standard.set(7, forKey: "dotdash_best_classic_v1")
        UserDefaults.standard.set(12, forKey: "dotdash_best_advanced_v1")
        let g = GameState()
        #expect(g.bestClassic == 7)
        #expect(g.bestAdvanced == 12)
    }

    @Test func legacyBestScoreMigratesToClassic() {
        clearBestScoreKeys()
        defer { clearBestScoreKeys() }
        UserDefaults.standard.set(9, forKey: "dotdash_best_v1")
        let g = GameState()
        #expect(g.bestClassic == 9)
        #expect(UserDefaults.standard.integer(forKey: "dotdash_best_classic_v1") == 9)
    }

    @Test func legacyMigrationDoesNotOverwriteExistingClassicBest() {
        clearBestScoreKeys()
        defer { clearBestScoreKeys() }
        UserDefaults.standard.set(9, forKey: "dotdash_best_v1")
        UserDefaults.standard.set(20, forKey: "dotdash_best_classic_v1")
        let g = GameState()
        #expect(g.bestClassic == 20)
    }

    @Test func gameOverPersistsNewBestClassic() {
        clearBestScoreKeys()
        defer { clearBestScoreKeys() }
        UserDefaults.standard.set(2, forKey: "dotdash_best_classic_v1")
        let g = GameState()
        g.mode = .classic
        g.running = true
        g.score = 5
        g.zoneCenter = 0.2
        g.zoneWidth = 0.1    // zone 0.15...0.25
        g.markerPos = 0.9    // clearly a miss
        g.handleTap(screenWidth: 320)
        #expect(g.gameOver == true)
        #expect(g.bestClassic == 5)
        #expect(UserDefaults.standard.integer(forKey: "dotdash_best_classic_v1") == 5)
    }

    @Test func gameOverDoesNotRegressBestClassic() {
        clearBestScoreKeys()
        defer { clearBestScoreKeys() }
        UserDefaults.standard.set(10, forKey: "dotdash_best_classic_v1")
        let g = GameState()
        g.mode = .classic
        g.running = true
        g.score = 3
        g.zoneCenter = 0.2
        g.zoneWidth = 0.1
        g.markerPos = 0.9
        g.handleTap(screenWidth: 320)
        #expect(g.bestClassic == 10)
        #expect(UserDefaults.standard.integer(forKey: "dotdash_best_classic_v1") == 10)
    }

    @Test func gameOverPersistsNewBestAdvanced() {
        clearBestScoreKeys()
        defer { clearBestScoreKeys() }
        let g = GameState()
        g.mode = .advanced
        g.running = true
        g.score = 8
        g.zoneCenter = 0.2
        g.zoneWidth = 0.1
        g.markerPos = 0.9
        g.handleTap(screenWidth: 320)
        #expect(g.bestAdvanced == 8)
        #expect(UserDefaults.standard.integer(forKey: "dotdash_best_advanced_v1") == 8)
        // Classic must not be touched by an advanced-mode miss.
        #expect(UserDefaults.standard.integer(forKey: "dotdash_best_classic_v1") == 0)
    }
}
