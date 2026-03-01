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
    /// SwiftUI `.confirmationDialog` maps to UIAlertController (action-sheet style),
    /// which runs in its own UIWindow. The Cancel button sits *beside* the action-
    /// buttons sheet (not inside it), so `app.sheets.descendants` never reaches it.
    ///
    /// On iOS 16+ Cancel has XCUIElementType.link (raw value 42) — the same cross-
    /// window access that `app.buttons` / `app.sheets` use also applies to
    /// `app.links`, making it the right query type. Coordinate-tap sidesteps the
    /// automation-type mismatch that blocks a plain `.tap()`.
    func tapCancel() {
        XCTAssertTrue(app.sheets.firstMatch.waitForExistence(timeout: 3), "Action sheet not found")
        let cancel = app.links.matching(NSPredicate(format: "label == 'Cancel'")).firstMatch
        XCTAssertTrue(cancel.waitForExistence(timeout: 2), "Cancel link not found in action sheet")
        cancel.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
    }
}
