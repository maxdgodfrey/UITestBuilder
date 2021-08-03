//
//  TestHarnessUITests.swift
//  TestHarnessUITests
//
//  Created by Max Godfrey on 3/06/21.
//

import XCTest
import UITestBuilder

class TestHarnessUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()
        
        test(application: app) {
            Given {
                loggedIn()
            }
            When {
                completedForm(number: "1234", text: "Hello")
            }
            Then {
                verifyOnHomescreen
            }
        }
    }
}

typealias Given = TestStep<Void>
typealias When = TestStep<Void>
typealias Then = TestStep<Void>

let dismissKeyboard: TestStep<Void> = find(\.keyboards.buttons).containing("return").onlyElement().tap()

@UITestBuilder
func loggedIn() -> TestStep<Void> {
    find(\.textFields).placeholder(containing: "Username").first().tap().type("FooBarson")
    find(\.secureTextFields).placeholder(containing: "Password").first().tap().type("TestPassword")
    find(\.buttons).containing("login").first().tap()
    verifyOnHomescreen
}

@UITestBuilder
func completedForm(number: String, text: String) -> TestStep<Void> {
    find(\.tables.buttons).containing("Show a form").first().tap()
    find(\.textFields).placeholder(containing: "Number input").first().wait().tap().wait().type(number)
    find(\.textFields).placeholder(containing: "Text input").first().tap().tap().type(text)
    dismissKeyboard
    find(\.buttons).containing("Submit").first().tap()
    find(\.sheets.buttons).containing("Confirm").first().tap()
}

let verifyOnHomescreen: TestStep<Void> = find(\.navigationBars.staticTexts).containing("Hello FooBarson").wait().onlyElement().exists()

func test(application: XCUIApplication, @UITestBuilder test: () -> TestStep<Void>) {
    do {
        try test()(application)
    } catch {
        guard let error = error as? TestStepError else {
            XCTFail(error.localizedDescription)
            return
        }
        XCTFail(error.description, file: error.file, line: error.line)
    }
}
