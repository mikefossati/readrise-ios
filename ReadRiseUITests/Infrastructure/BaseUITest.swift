import XCTest

@MainActor
class BaseUITest: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launchArguments = ["--uitesting"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app.terminate()
    }

    // MARK: - Helpers

    /// Wait for an element to exist and be hittable.
    @discardableResult
    func waitFor(_ element: XCUIElement, timeout: TimeInterval = 5) -> XCUIElement {
        XCTAssertTrue(element.waitForExistence(timeout: timeout),
                      "Element '\(element)' did not appear within \(timeout)s")
        return element
    }

    /// Tap a tab by its label string.
    func tapTab(_ label: String) {
        app.tabBars.firstMatch.buttons[label].tap()
    }

    /// Tap the "Cancel" button inside the frontmost action sheet.
    ///
    /// SwiftUI `.confirmationDialog` maps to UIAlertController (action-sheet style).
    /// Cancel sits in its own element outside the main sheet subtree and has a
    /// non-standard XCUIElementType on iOS 16+, making element queries unreliable.
    ///
    /// Coordinate-tapping at ~93 % of the screen height (just above the home
    /// indicator) is the most reliable cross-version approach.
    func tapCancel() {
        XCTAssertTrue(app.sheets.firstMatch.waitForExistence(timeout: 3), "Action sheet not found")
        // Cancel always appears near the bottom of the screen in a UIAlertController
        // action sheet, just above the home indicator safe-area.
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.93)).tap()
    }
}
