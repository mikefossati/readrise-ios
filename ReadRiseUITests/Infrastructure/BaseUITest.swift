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
    /// UIAlertController (used by SwiftUI `.confirmationDialog`) runs in its own
    /// UIWindow, separate from the app's main window hierarchy. `app.descendants`
    /// only searches the main window, so it never finds the Cancel button.
    /// `app.sheets` crosses UIWindow boundaries; searching its descendants finds
    /// the element regardless of automation type (type 42 / "link" on iOS 16+).
    /// Coordinate-tap bypasses the automation-type mismatch check on tap.
    func tapCancel() {
        XCTAssertTrue(app.sheets.firstMatch.waitForExistence(timeout: 3), "Action sheet not found")
        let cancel = app.sheets.descendants(matching: .any)
            .matching(NSPredicate(format: "label == 'Cancel'"))
            .firstMatch
        XCTAssertTrue(cancel.waitForExistence(timeout: 2), "Cancel not found in action sheet")
        cancel.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
    }
}
