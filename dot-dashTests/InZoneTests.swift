//
//  InZoneTests.swift
//  dot-dashTests
//
//  Direct coverage for GameState.inZone(_:) — the hit/miss decision function.
//

import Testing
import UIKit
@testable import dot_dash

@MainActor
@Suite
struct InZoneTests {

    /// Fresh GameState with an explicit zone: center 0.5, width 0.4 → spans 0.3...0.7.
    private func makeStandardZone() -> GameState {
        let g = GameState()
        g.zoneCenter = 0.5
        g.zoneWidth = 0.4
        return g
    }

    // MARK: - Center hit

    @Test func inZoneAtZoneCenterIsTrue() {
        let g = makeStandardZone()
        #expect(g.inZone(0.5) == true)
    }

    // MARK: - Just inside the edges

    @Test func inZoneJustInsideEdgesIsTrue() {
        let g = makeStandardZone()
        #expect(g.inZone(0.301) == true)
        #expect(g.inZone(0.699) == true)
    }

    // MARK: - Exactly on the edges (inclusive contract: >= and <=)

    @Test func inZoneExactlyOnEdgesIsTrue() {
        let g = makeStandardZone()
        // Compute edges with the same arithmetic the implementation uses,
        // so binary-inexact literals can't cause a spurious off-by-ULP failure.
        let half = g.zoneWidth / 2
        let lowerEdge = g.zoneCenter - half
        let upperEdge = g.zoneCenter + half
        #expect(g.inZone(lowerEdge) == true)
        #expect(g.inZone(upperEdge) == true)
    }

    // MARK: - Just outside the edges

    @Test func inZoneJustOutsideEdgesIsFalse() {
        let g = makeStandardZone()
        #expect(g.inZone(0.299) == false)
        #expect(g.inZone(0.701) == false)
    }

    // MARK: - Markers at the track extremes vs an edge-hugging zone

    @Test func markerAtZeroVersusLeftEdgeZone() {
        let g = GameState()
        g.zoneCenter = 0.15

        // Narrow zone: spans 0.05...0.25 → marker at 0.0 misses.
        g.zoneWidth = 0.2
        #expect(g.inZone(0.0) == false)

        // Wide zone: spans -0.05...0.35 → marker at 0.0 hits.
        g.zoneWidth = 0.4
        #expect(g.inZone(0.0) == true)
    }

    @Test func markerAtOneVersusRightEdgeZone() {
        let g = GameState()
        g.zoneCenter = 0.85

        // Narrow zone: spans 0.75...0.95 → marker at 1.0 misses.
        g.zoneWidth = 0.2
        #expect(g.inZone(1.0) == false)

        // Wide zone: spans 0.65...1.05 → marker at 1.0 hits.
        g.zoneWidth = 0.4
        #expect(g.inZone(1.0) == true)
    }

    // MARK: - Tiny zone (advanced-mode minimum width)

    @Test func tinyZoneStillDetectsCenterHit() {
        let g = GameState()
        g.zoneCenter = 0.5
        g.zoneWidth = 0.06  // advanced-mode minZoneWidth → spans 0.47...0.53
        #expect(g.inZone(0.5) == true)
        #expect(g.inZone(0.46) == false)
        #expect(g.inZone(0.54) == false)
    }
}
