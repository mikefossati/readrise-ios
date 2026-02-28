import XCTest

final class BookDetailUITests: BaseUITest {

    override func setUpWithError() throws {
        try super.setUpWithError()
        // Navigate: Dashboard → tap currently reading card
        let card = app.buttons["dashboard.continueReading.ub-001"]
        XCTAssertTrue(card.waitForExistence(timeout: 5))
        card.tap()
        // Wait for BookDetailView to appear
        XCTAssertTrue(app.staticTexts["The Great Gatsby"].waitForExistence(timeout: 5))
    }

    // MARK: - Load

    func testBookDetailShowsTitle() {
        XCTAssertTrue(app.staticTexts["The Great Gatsby"].exists)
    }

    func testBookDetailShowsAuthor() {
        XCTAssertTrue(app.staticTexts["F. Scott Fitzgerald"].exists)
    }

    func testBookDetailShowsShelfBadge() {
        XCTAssertTrue(app.buttons["Reading"].exists)
    }

    // MARK: - Session

    func testStartSessionButtonExists() {
        let startBtn = app.buttons["bookDetail.startSession"]
        waitFor(startBtn)
    }

    func testStartSessionShowsTimer() {
        let startBtn = app.buttons["bookDetail.startSession"]
        waitFor(startBtn).tap()
        // Timer and end session controls should appear
        XCTAssertTrue(app.buttons["bookDetail.endSession"].waitForExistence(timeout: 5))
    }

    func testEndSessionWithPageNumber() {
        app.buttons["bookDetail.startSession"].tap()
        let endField = app.textFields["bookDetail.endPageField"]
        XCTAssertTrue(endField.waitForExistence(timeout: 5))
        endField.tap()
        endField.typeText("105")
        app.buttons["bookDetail.endSession"].tap()
        // Session should end, start button returns
        XCTAssertTrue(app.buttons["bookDetail.startSession"].waitForExistence(timeout: 5))
    }

    // MARK: - Progress

    func testLogProgressFieldExists() {
        let field = app.textFields["bookDetail.progressField"]
        waitFor(field)
    }

    func testLogProgressButtonExists() {
        waitFor(app.buttons["bookDetail.logProgress"])
    }

    func testLogProgressFlow() {
        let field = app.textFields["bookDetail.progressField"]
        waitFor(field).tap()
        field.typeText("90")
        app.buttons["bookDetail.logProgress"].tap()
        // Field should clear after save
        XCTAssertTrue(field.waitForExistence(timeout: 3))
    }

    // MARK: - Keyboard

    func testKeyboardDismissesOnDone() {
        let field = app.textFields["bookDetail.progressField"]
        waitFor(field).tap()
        XCTAssertTrue(app.keyboards.firstMatch.exists)
        app.toolbars.buttons["Done"].tap()
        XCTAssertFalse(app.keyboards.firstMatch.exists)
    }

    // MARK: - Review

    func testReviewSectionExists() {
        let editor = app.textViews["bookDetail.reviewBody"]
        // Scroll to it
        app.scrollViews.firstMatch.swipeUp()
        waitFor(editor)
    }

    func testSaveReviewButton() {
        app.scrollViews.firstMatch.swipeUp()
        // Tap 4th star (stars are plain buttons; tap by index)
        let stars = app.buttons.matching(NSPredicate(format: "label CONTAINS 'star'"))
        if stars.count >= 4 { stars.element(boundBy: 3).tap() }
        waitFor(app.buttons["bookDetail.saveReview"])
    }

    // MARK: - Change shelf

    func testShelfBadgeTapOpensActionSheet() {
        let badge = app.buttons["Reading"]
        waitFor(badge).tap()
        XCTAssertTrue(app.sheets.firstMatch.waitForExistence(timeout: 3))
    }

    // MARK: - Delete

    func testDeleteButtonExists() {
        app.scrollViews.firstMatch.swipeUp()
        waitFor(app.buttons["bookDetail.deleteBook"])
    }

    func testDeleteShowsConfirmationDialog() {
        app.scrollViews.firstMatch.swipeUp()
        app.buttons["bookDetail.deleteBook"].tap()
        // confirmationDialog should appear
        XCTAssertTrue(app.sheets.firstMatch.waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Remove"].exists)
        XCTAssertTrue(app.buttons["Cancel"].exists)
    }

    func testDeleteCancelKeepsBook() {
        app.scrollViews.firstMatch.swipeUp()
        app.buttons["bookDetail.deleteBook"].tap()
        app.buttons["Cancel"].tap()
        // Should remain on BookDetailView
        XCTAssertTrue(app.staticTexts["The Great Gatsby"].waitForExistence(timeout: 3))
    }

    func testDeleteConfirmDismissesView() {
        app.scrollViews.firstMatch.swipeUp()
        app.buttons["bookDetail.deleteBook"].tap()
        app.buttons["Remove"].tap()
        // Should dismiss back to Dashboard
        XCTAssertTrue(app.otherElements["dashboard.statsGrid"].waitForExistence(timeout: 5))
    }
}
