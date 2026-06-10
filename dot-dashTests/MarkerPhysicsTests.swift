//
//  MarkerPhysicsTests.swift
//  dot-dashTests
//
//  Tests for GameState.advanceMarker, the pure marker movement + edge bounce
//  function extracted from the CADisplayLink step loop.
//

import Testing
import CoreGraphics
@testable import dot_dash

struct MarkerPhysicsTests {

    @Test func plainAdvanceMovesRightByDirSpeedDt() {
        let result = GameState.advanceMarker(pos: 0.5, dir: 1, speed: 0.65, dt: 0.016)
        let expected: CGFloat = 0.5 + 0.65 * 0.016
        #expect(abs(result.pos - expected) < 1e-9)
        #expect(result.dir == 1)
    }

    @Test func movingLeftDecreasesPositionSymmetrically() {
        let result = GameState.advanceMarker(pos: 0.5, dir: -1, speed: 0.65, dt: 0.016)
        let expected: CGFloat = 0.5 - 0.65 * 0.016
        #expect(abs(result.pos - expected) < 1e-9)
        #expect(result.dir == -1)
    }

    @Test func rightEdgeBounceClampsToOneAndFlipsDirection() {
        let result = GameState.advanceMarker(pos: 0.99, dir: 1, speed: 1.0, dt: 0.05)
        #expect(result.pos == 1)
        #expect(result.dir == -1)
    }

    @Test func leftEdgeBounceClampsToZeroAndFlipsDirection() {
        let result = GameState.advanceMarker(pos: 0.01, dir: -1, speed: 1.0, dt: 0.05)
        #expect(result.pos == 0)
        #expect(result.dir == 1)
    }

    @Test func landingExactlyOnOneTriggersBounceBecauseComparisonIsInclusive() {
        // 0.9 + 1 * 2.0 * 0.05 == 1.0 exactly; the >= comparison must bounce.
        let result = GameState.advanceMarker(pos: 0.9, dir: 1, speed: 2.0, dt: 0.05)
        #expect(result.pos == 1)
        #expect(result.dir == -1)
    }

    @Test func overshootIsClampedNotReflected() {
        // Documents current behavior: a huge step clamps to the edge rather
        // than reflecting the excess distance back into the track.
        let result = GameState.advanceMarker(pos: 0.5, dir: 1, speed: 100, dt: 0.05)
        #expect(result.pos == 1)
        #expect(result.dir == -1)
    }

    @Test func zeroDtIsNoOp() {
        let result = GameState.advanceMarker(pos: 0.5, dir: 1, speed: 0.65, dt: 0)
        #expect(result.pos == 0.5)
        #expect(result.dir == 1)
    }

    @Test func tenSecondSimulationStaysInBoundsAndBouncesRepeatedly() {
        var pos: CGFloat = 0.5
        var dir: CGFloat = 1
        let speed: CGFloat = 0.8
        let dt: CGFloat = 1.0 / 60.0
        var flips = 0
        for _ in 0..<600 {
            let prevDir = dir
            (pos, dir) = GameState.advanceMarker(pos: pos, dir: dir, speed: speed, dt: dt)
            #expect(pos >= 0 && pos <= 1)
            if dir != prevDir { flips += 1 }
        }
        #expect(flips >= 2)
    }

    @Test func degenerateHugeStepFromLeftEdgeClampsToRightEdge() {
        // 0 + 1 * 30 * 0.05 = 1.5 → first branch clamps to (1, -1);
        // the subsequent <= 0 check is false, so the result stands.
        let result = GameState.advanceMarker(pos: 0, dir: 1, speed: 30, dt: 0.05)
        #expect(result.pos == 1)
        #expect(result.dir == -1)
    }

    @Test func degenerateHugeStepFromRightEdgeClampsToLeftEdge() {
        // 1 + (-1) * 30 * 0.05 = -0.5 → >= 1 branch is false,
        // <= 0 branch sets (0, 1).
        let result = GameState.advanceMarker(pos: 1, dir: -1, speed: 30, dt: 0.05)
        #expect(result.pos == 0)
        #expect(result.dir == 1)
    }
}
