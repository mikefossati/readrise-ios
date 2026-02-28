import XCTest

final class LibraryUITests: BaseUITest {

    override func setUpWithError() throws {
        try super.setUpWithError()
        tapTab("Library")
    }

    // MARK: - Load

    func testLibraryShowsNowReadingSection() {
        // Fixture: ub-001 is on "reading" shelf
        let card = app.buttons["library.book.ub-001"]
        waitFor(card)
        XCTAssertTrue(card.exists)
    }

    func testLibraryToolbarHasAddAndScanButtons() {
        XCTAssertTrue(app.buttons["library.addBook"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["library.barcodeButton"].exists)
    }

    // MARK: - Shelf tabs

    func testLibraryShelfPickerExists() {
        waitFor(app.segmentedControls["library.shelfPicker"])
    }

    func testSwitchingToFinishedShelfShowsBook() {
        let picker = app.segmentedControls["library.shelfPicker"]
        waitFor(picker)
        picker.buttons["Finished"].tap()
        // Fixture: ub-003 is on "finished" shelf
        waitFor(app.buttons["library.book.ub-003"])
    }

    func testSwitchingToToReadShelfShowsBook() {
        let picker = app.segmentedControls["library.shelfPicker"]
        waitFor(picker)
        picker.buttons["To Read"].tap()
        // Fixture: ub-002 is "want_to_read"
        waitFor(app.buttons["library.book.ub-002"])
    }

    func testEmptyAbandonedShelf() {
        let picker = app.segmentedControls["library.shelfPicker"]
        waitFor(picker)
        picker.buttons["Abandoned"].tap()
        // Fixture has no abandoned books → empty state text
        let emptyText = app.staticTexts["No abandoned books"]
        XCTAssertTrue(emptyText.waitForExistence(timeout: 3))
    }

    // MARK: - Add book sheet

    func testTappingAddBookOpensSearchSheet() {
        app.buttons["library.addBook"].tap()
        // BookSearchView has a navigation title "Add a Book"
        let title = app.navigationBars["Add a Book"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))
    }

    func testAddBookSearchShowsResults() {
        app.buttons["library.addBook"].tap()
        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        searchField.tap()
        searchField.typeText("Atomic")
        // Fixture returns 2 results
        let result = app.buttons["bookSearch.add.gv-001"]
        XCTAssertTrue(result.waitForExistence(timeout: 5))
    }

    func testAddBookAndDismissSearchSheet() {
        app.buttons["library.addBook"].tap()
        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        searchField.tap()
        searchField.typeText("Atomic")

        let addBtn = app.buttons["bookSearch.add.gv-001"]
        XCTAssertTrue(addBtn.waitForExistence(timeout: 5))
        addBtn.tap()

        // Sheet should dismiss and library reload
        XCTAssertTrue(app.buttons["library.addBook"].waitForExistence(timeout: 5))
    }

    // MARK: - Delete via context menu

    func testLongPressNowReadingCardShowsDeleteOption() {
        let card = app.buttons["library.book.ub-001"]
        waitFor(card).press(forDuration: 1.0)

        let deleteOption = app.buttons["Remove from library"]
        XCTAssertTrue(deleteOption.waitForExistence(timeout: 3))
    }

    // MARK: - Navigate to book detail

    func testTappingNowReadingCardOpensBookDetail() {
        waitFor(app.buttons["library.book.ub-001"]).tap()
        XCTAssertTrue(app.staticTexts["The Great Gatsby"].waitForExistence(timeout: 5))
    }
}
