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

### Enter `TestStep`

To achive a sussinct, consistent syntax, let's examine what we actually need to do our three types of _things_ in tests. It all stems from an instance of XCUIApplication, from there we can create XCUIElementQueries, XCUIElements. 

This is all a `TestStep` is, a lightweight wrapper around a function from `XCUIApplication`* to a generic `Result` type. Why wrap a function, well it let's us compose `TestStep`s to form our tests. It allows us to define test steps, composing them without the actual `XCUIApplication` instance. 

### Your go to entrypoint `find(:_)`

In a regular XCTest you might locate an element by reaching into the current `XCUIApplication`, for instance
`XCUIApplication().textFields["Username"]`. There's two parts at play, the first call to `textFields` creates a `XCUIElementQuery`, and the subscript runs that query looking for textfields matching exactly the supplied string `"Username"`. 

The `find(:_)` function lets you get a `XCUIElementQuery`, and it really shines with keypaths:
`find(\.textFiels)`. This returns a `TestStep<XCUIElementQuery>` which you can then narrow down or create further specific queries:
`find(\.scrollViews.textFields).matching(exactly: "Username")`. 

#### Narrowing your query

Let's take a look at how you might factor our finding some element that contains some substring, good for when your XCUIElement label is driven by dynamic data:
```
XCUIApplication().staticTexts.matchingPredicate(NSPredicate(format: "label CONTAINS[c] %@", "Spicy Ghost Peppers"))
```
Tucking the predicate and factoring this into a helper:
```
XCUIApplication().staticTexts.matchingPredicate(.labelContains("Spicy Ghost Peppers"))
// Perhaps you tuck this away into a helper 
extension XCUIElementQuery {
    
    func containing(_ text: String) -> XCUIElementQuery {
        matchingPredicate(.labelContains(text))
    }
}
```
We end up with:
```
let spicyButton = XCUIApplication().staticTexts.containing("Spicy Ghost Peppers")
```
Not bad at all, and with `TestSteps` we look very similar:
```
find(\.staticTexts).containing("Spicy Ghost Peppers")
```

So far it's just different not better! So, let's examine interaction

### Interacting 
