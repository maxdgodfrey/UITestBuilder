# UITestBuilder

UITestBuilder provides an opinionated, safe and composable wrapper API around Apple's UI Testing APIs. 

UI tests can be distilled down to three steps:
1. Finding XCUIElements on screen.
2. Interacting with XCUIElements.
3. Verifying the state of XCUIElements. 

For example take this snippet for a Login Screen. Our intent is to log in, and our test relfects the actions the user must do to achieve that.
```
func testLogin() throws {
    let app = XCUIApplication()

    // Given I've entered valid credentials
    let emailField = app.textFields["Email"]
    XCTAssert(emailField.waitForExistence(timeout: 10))
    emailField.tap()
    emailField.typeText("foo@bar.com")

    let passwordField = app.secureTextFields["Password"]
    passwordField.tap()
    passwordField.typeText("<# Redacted #>")

    // When I log in successfull
    app.buttons["Login"].tap()

    // Then I should see the homscreen, signaled by the presence of the navigation bar title.
    let homeScreenTitle = app.navigationBars.staticTexts["Home"]
    XCTAssert(homeScreenTitle.waitForExistence(timeout: 30))
}
```

Not too bad. You may need to log in from many of your UI Tests, so following our friends in the web world, you might use the PageObject pattern. Let's call this a Screen because we aren't in a browser! Following your nose, the interactions and verifications are pushed into a Screen type.

```
enum LoginScreen {

    static func enterEmailAndPassword(_ email: String, _ password: String) -> LoginScreen.Type {
        let app = XCUIApplication.shared

        let emailField = app.textFields["Email"]
        XCTAssert(emailField.waitForExistence(timeout: 10))
        emailField.tap()
        emailField.typeText(email)

        let passwordField = app.secureTextFields["Password"]
        passwordField.tap()
        passwordField.typeText(password)
    }

    static func tapLogin() -> HomeScreen.Type {
        XCUIApplication.shared.buttons["Login"].tap()
    }
}

enum HomeScreen {

    static func verifyOnHomeScreen() -> HomeScreen.Type {
        let homeScreenTitle = XCUIApplication.shared.navigationBars.staticTexts["Home"]
        XCTAssert(homeScreenTitle.waitForExistence(timeout: 30))
    }
}


func testLogin() throws {
    LoginScreen.enterEmailAndPassword("foo@bar.com", "<# Redacted #>")
        .tapLogin()
        .verifyOnHomeScreen()
}
```

All we've done is factor the test into some parameterized helper code, nothing to write home about. The code within the screen type is the same; we locate elements onscreen, make assertions and interact. UITestBuidlers make this, the locating, interacting and asserting a breeze 💨.
