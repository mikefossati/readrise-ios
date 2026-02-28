import XCTest

// Auth tests use --show-auth to force AuthView regardless of any cached session.
final class AuthUITests: XCTestCase {

    private func launchForAuth() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--show-auth"]
        app.launch()
        return app
    }

    func testAuthViewShowsSignInButtons() throws {
        let app = launchForAuth()
        let appleBtn = app.buttons["auth.signInApple"]
        XCTAssertTrue(appleBtn.waitForExistence(timeout: 5), "Sign in with Apple button not found")
        let googleBtn = app.buttons["auth.signInGoogle"]
        XCTAssertTrue(googleBtn.waitForExistence(timeout: 2), "Continue with Google button not found")
        app.terminate()
    }

    func testAuthViewShowsBothButtonsEnabled() throws {
        let app = launchForAuth()
        let appleBtn = app.buttons["auth.signInApple"]
        XCTAssertTrue(appleBtn.waitForExistence(timeout: 5))
        XCTAssertTrue(appleBtn.isEnabled)
        let googleBtn = app.buttons["auth.signInGoogle"]
        XCTAssertTrue(googleBtn.isEnabled)
        app.terminate()
    }
}
