import XCTest

final class ProfileUITests: BaseUITest {

    override func setUpWithError() throws {
        try super.setUpWithError()
        tapTab("Profile")
    }

    // MARK: - Load

    func testProfileViewLoads() {
        XCTAssertTrue(app.navigationBars["Profile"].waitForExistence(timeout: 5))
    }

    func testProfileDisplaysName() {
        // Fixture user_profile.json has display_name = "Test Reader"
        let nameField = app.textFields["profile.nameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        XCTAssertEqual(nameField.value as? String, "Test Reader")
    }

    func testProfileHasSaveButton() {
        waitFor(app.buttons["profile.saveName"])
    }

    func testProfileHasSignOutButton() {
        waitFor(app.buttons["profile.signOut"])
    }

    // MARK: - Edit name

    func testSaveNameButtonEnabledWhenNamePresent() {
        let field = app.textFields["profile.nameField"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["profile.saveName"].isEnabled)
    }

    func testEditAndSaveName() {
        let field = app.textFields["profile.nameField"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.clearAndEnterText("New Name")
        app.buttons["profile.saveName"].tap()
        // Success toast "Name saved" should appear briefly
        let toast = app.staticTexts["Name saved"]
        XCTAssertTrue(toast.waitForExistence(timeout: 3))
    }

    // MARK: - Sign out

    func testSignOutShowsConfirmation() {
        app.buttons["profile.signOut"].tap()
        XCTAssertTrue(app.sheets.firstMatch.waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Sign out"].exists)
    }

    func testSignOutCancelStaysOnProfile() {
        app.buttons["profile.signOut"].tap()
        app.buttons["Cancel"].tap()
        XCTAssertTrue(app.navigationBars["Profile"].waitForExistence(timeout: 3))
    }
}

// MARK: - XCUIElement helper

extension XCUIElement {
    /// Clears existing text and types new text.
    func clearAndEnterText(_ text: String) {
        guard let currentValue = value as? String, !currentValue.isEmpty else {
            tap()
            typeText(text)
            return
        }
        tap()
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: currentValue.count)
        typeText(deleteString)
        typeText(text)
    }
}
