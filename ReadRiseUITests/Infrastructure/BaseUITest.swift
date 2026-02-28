import XCTest

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
}
