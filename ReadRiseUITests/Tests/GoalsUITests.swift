import XCTest

final class GoalsUITests: BaseUITest {

    override func setUpWithError() throws {
        try super.setUpWithError()
        tapTab("Goals")
    }

    // MARK: - Load

    func testGoalsViewLoads() {
        // Goal card should appear (fixture has a goal set)
        XCTAssertTrue(app.navigationBars["Reading Goals"].waitForExistence(timeout: 5))
    }

    func testGoalProgressDisplayed() {
        // Fixture: 7 books read of 24 target
        let books = app.staticTexts["7"]
        XCTAssertTrue(books.waitForExistence(timeout: 5))
    }

    func testGoalPaceMessageDisplayed() {
        // Fixture stats + goal → pace message visible
        let pace = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'pace'"))
        // At least one text containing "pace"
        XCTAssertTrue(pace.firstMatch.waitForExistence(timeout: 5))
    }

    // MARK: - Set goal

    func testSetGoalFieldExists() {
        let field = app.textFields["goals.targetField"]
        waitFor(field)
    }

    func testSaveGoalButtonExists() {
        waitFor(app.buttons["goals.saveGoal"])
    }

    func testSaveGoalButtonDisabledWhenEmpty() {
        let field = app.textFields["goals.targetField"]
        waitFor(field)
        XCTAssertFalse(app.buttons["goals.saveGoal"].isEnabled)
    }

    func testSaveGoalButtonEnabledAfterInput() {
        let field = app.textFields["goals.targetField"]
        waitFor(field).tap()
        field.typeText("12")
        XCTAssertTrue(app.buttons["goals.saveGoal"].isEnabled)
    }

    func testSetGoalFlow() {
        let field = app.textFields["goals.targetField"]
        waitFor(field).tap()
        field.typeText("12")
        app.buttons["goals.saveGoal"].tap()
        // Goal created fixture returns target=12; no error should appear
        XCTAssertFalse(app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'error'")).firstMatch.exists)
    }

    // MARK: - Preset buttons

    func testPresetButtonsFillField() {
        let preset = app.buttons["12 books"]
        XCTAssertTrue(preset.waitForExistence(timeout: 5))
        preset.tap()
        let field = app.textFields["goals.targetField"]
        XCTAssertEqual(field.value as? String, "12")
    }

    // MARK: - Pull to refresh

    func testPullToRefreshOnGoals() {
        waitFor(app.navigationBars["Reading Goals"])
        app.scrollViews.firstMatch.swipeDown()
        XCTAssertTrue(app.navigationBars["Reading Goals"].waitForExistence(timeout: 5))
    }
}
