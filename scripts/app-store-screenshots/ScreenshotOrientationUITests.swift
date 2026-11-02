// App Store screenshot staging. Copied into dot-dashUITests/ by
// scripts/capture-app-store-screenshots.sh and removed afterward.
//
// simctl has no rotate command, and in Full Screen Apps mode iPadOS won't let
// the app rotate itself, so these set the simulated device's orientation. It
// stays after the test ends, so later `simctl launch`es open in it.

import XCTest

final class ScreenshotOrientationUITests: XCTestCase {
    @MainActor
    func testSetLandscape() {
        XCUIDevice.shared.orientation = .landscapeLeft
    }

    @MainActor
    func testSetPortrait() {
        XCUIDevice.shared.orientation = .portrait
    }
}
