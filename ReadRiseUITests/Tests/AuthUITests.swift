import XCTest

// Auth tests launch WITHOUT --uitesting so the real AuthView is shown.
final class AuthUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testAuthViewShowsSignInButtons() throws {
        let app = XCUIApplication()
        app.launchArguments = []   // no --uitesting → real auth gate
        app.launch()

        // The app may show a splash briefly; wait for auth view
        let appleBtn = app.buttons["auth.signInApple"]
        XCTAssertTrue(appleBtn.waitForExistence(timeout: 5), "Sign in with Apple button not found")

        let googleBtn = app.buttons["auth.signInGoogle"]
        XCTAssertTrue(googleBtn.waitForExistence(timeout: 2), "Continue with Google button not found")

        app.terminate()
    }

    func testAuthViewShowsBothButtonsEnabled() throws {
        let app = XCUIApplication()
        app.launchArguments = []
        app.launch()

        let appleBtn = app.buttons["auth.signInApple"]
        XCTAssertTrue(appleBtn.waitForExistence(timeout: 5))
        XCTAssertTrue(appleBtn.isEnabled)

        let googleBtn = app.buttons["auth.signInGoogle"]
        XCTAssertTrue(googleBtn.isEnabled)

        app.terminate()
    }
}
