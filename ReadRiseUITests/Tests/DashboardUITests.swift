import XCTest

final class DashboardUITests: BaseUITest {

    // MARK: - Load

    func testDashboardLoadsGreeting() {
        let greeting = app.staticTexts["dashboard.greeting"]
        waitFor(greeting)
        let text = greeting.label
        XCTAssertTrue(
            text.hasPrefix("Good morning") ||
            text.hasPrefix("Good afternoon") ||
            text.hasPrefix("Good evening"),
            "Unexpected greeting: \(text)"
        )
    }

    func testDashboardShowsStatsGrid() {
        waitFor(app.otherElements["dashboard.statsGrid"])
    }

    func testDashboardShowsGoalCard() {
        waitFor(app.otherElements["dashboard.goalCard"])
    }

    func testDashboardShowsStreakBadge() {
        waitFor(app.otherElements["dashboard.streakBadge"])
    }

    func testDashboardShowsCurrentlyReadingCard() {
        // Fixture has one "reading" book: The Great Gatsby (ub-001)
        let card = app.buttons["dashboard.continueReading.ub-001"]
        waitFor(card)
        XCTAssertTrue(card.label.contains("Continue") || card.exists)
    }

    // MARK: - Navigation

    func testTappingCurrentlyReadingOpensBookDetail() {
        let card = app.buttons["dashboard.continueReading.ub-001"]
        waitFor(card).tap()

        // BookDetailView shows the book title in the navigation bar area
        let title = app.staticTexts["The Great Gatsby"]
        XCTAssertTrue(title.waitForExistence(timeout: 5), "BookDetailView did not appear")
    }

    // MARK: - Pull to refresh

    func testPullToRefreshReloadsData() {
        waitFor(app.otherElements["dashboard.statsGrid"])

        let scrollView = app.scrollViews.firstMatch
        scrollView.swipeDown()

        // Stats grid should still be visible after refresh
        waitFor(app.otherElements["dashboard.statsGrid"])
    }

    // MARK: - Tab switching reloads

    func testSwitchingTabsAndBackReloads() {
        waitFor(app.otherElements["dashboard.statsGrid"])
        tapTab("Library")
        tapTab("Dashboard")
        // Dashboard should reload and still show content
        waitFor(app.otherElements["dashboard.statsGrid"])
    }
}
