//
//  dot_dashUITests.swift
//  dot-dashUITests
//
//  Created by Ronan Kenkare on 8/8/25.
//

import XCTest

final class dot_dashUITests: XCTestCase {

    override func setUpWithError() throws {
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
    }

    // MARK: - Helpers

    /// Waits until the element's accessibility label contains the given text.
    @MainActor
    private func waitForLabel(of element: XCUIElement, toContain text: String, timeout: TimeInterval = 5) -> Bool {
        let predicate = NSPredicate(format: "label CONTAINS %@", text)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }

    // MARK: - Tests

    @MainActor
    func testLaunchShowsHomeScreen() throws {
        let app = XCUIApplication()
        app.launch()

        let title = app.staticTexts["Dot • Dash"].firstMatch
        XCTAssertTrue(title.waitForExistence(timeout: 10), "Home title 'Dot • Dash' should be visible after launch")

        let playButton = app.buttons["home.playButton"].firstMatch
        XCTAssertTrue(playButton.waitForExistence(timeout: 5), "Play button should be visible on the home screen")
    }

    @MainActor
    func testModeToggleFlipsLabel() throws {
        let app = XCUIApplication()
        app.launch()

        let pill = app.buttons["home.modePill"].firstMatch
        XCTAssertTrue(pill.waitForExistence(timeout: 10), "Mode pill should be visible on the home screen")

        // Read the starting state instead of assuming Classic — read-then-assert is
        // robust even if a previous run somehow altered defaults.
        let startsClassic = pill.label.contains("Classic")
        XCTAssertTrue(startsClassic || pill.label.contains("Advanced"),
                      "Mode pill label should mention Classic or Advanced, was '\(pill.label)'")
        let flippedMode = startsClassic ? "Advanced" : "Classic"
        let originalMode = startsClassic ? "Classic" : "Advanced"

        pill.tap()
        XCTAssertTrue(waitForLabel(of: pill, toContain: flippedMode),
                      "Mode pill should flip to \(flippedMode) after one tap, was '\(pill.label)'")

        pill.tap()
        XCTAssertTrue(waitForLabel(of: pill, toContain: originalMode),
                      "Mode pill should flip back to \(originalMode) after a second tap, was '\(pill.label)'")
    }

    @MainActor
    func testPlayNavigatesToGame() throws {
        let app = XCUIApplication()
        app.launch()

        let playButton = app.buttons["home.playButton"].firstMatch
        XCTAssertTrue(playButton.waitForExistence(timeout: 10), "Play button should be visible on the home screen")
        playButton.tap()

        let overlay = app.descendants(matching: .any).matching(identifier: "game.helpOverlay").firstMatch
        XCTAssertTrue(overlay.waitForExistence(timeout: 10), "Help overlay should appear on the game screen")

        XCTAssertTrue(app.staticTexts["How To Play"].firstMatch.waitForExistence(timeout: 5),
                      "'How To Play' text should be shown in the help overlay")
        XCTAssertTrue(app.buttons["game.startButton"].firstMatch.exists,
                      "Start button should be shown in the help overlay")
    }

    @MainActor
    func testTapScoresOrEndsGame() throws {
        let app = XCUIApplication()
        app.launch()

        let playButton = app.buttons["home.playButton"].firstMatch
        XCTAssertTrue(playButton.waitForExistence(timeout: 10), "Play button should be visible on the home screen")
        playButton.tap()

        let startButton = app.buttons["game.startButton"].firstMatch
        XCTAssertTrue(startButton.waitForExistence(timeout: 10), "Start button should appear before the run begins")
        startButton.tap()

        // Tap the center of the screen up to 30 times. The dot moves randomly, so
        // each tap may score or miss; a miss ends the run. Break as soon as the
        // game-over overlay shows up — further taps would restart the game.
        let gameOverTitle = app.staticTexts["Game Over"].firstMatch
        let center = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        var sawGameOver = false
        for _ in 0..<30 {
            center.tap()
            // Doubles as the brief gap between taps.
            if gameOverTitle.waitForExistence(timeout: 0.4) {
                sawGameOver = true
                break
            }
        }

        if sawGameOver {
            return // Terminal state reached: a miss ended the run, which is expected.
        }

        // No game over within 30 taps — then at least some taps must have scored.
        let scoreLabel = app.staticTexts["game.scoreLabel"].firstMatch
        XCTAssertTrue(scoreLabel.waitForExistence(timeout: 5), "Score label should be visible during a run")
        let digits = scoreLabel.label.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        let score = Int(digits) ?? 0
        XCTAssertGreaterThan(score, 0,
                             "After 30 taps, expected either 'Game Over' or a score > 0 (score label was '\(scoreLabel.label)')")
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
