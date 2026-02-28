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
    /// SwiftUI's `.confirmationDialog` Cancel has automation type 42 ("link") on
    /// iOS 16+, so it is invisible to `app.buttons["Cancel"]`. Searching the full
    /// descendant tree by label finds it regardless of element type.
    func tapCancel() {
        let sheet = app.sheets.firstMatch
        _ = sheet.waitForExistence(timeout: 3)
        let cancel = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label == 'Cancel'"))
            .firstMatch
        XCTAssertTrue(cancel.waitForExistence(timeout: 3), "Cancel button not found")
        cancel.tap()
    }
}
