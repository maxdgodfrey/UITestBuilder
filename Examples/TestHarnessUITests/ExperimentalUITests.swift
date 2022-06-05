//
//  ExperimentalUITests.swift
//
//
//  Created by Max Godfrey on 12/09/21.
//
import UITestBuilder
import XCTest

class ExperimentalUITests: XCTest {

    func testExperimentalScreenType() throws {
        let app = XCUIApplication()
        app.launch()
        test(application: app) {
            Login.start()
                .login(username: "max", password: "password")
                .acceptOnboarding()
                .showSettings()
                .toVoidStep()
        }
    }
}

enum Login: TestStepScreen {}
extension TestStep where Result == Login.Type {

    func login(username: String, password: String) -> TestStep<Dashboard.Type> {
        steps(
            find(\.textFields).placeholder(containing: "username").first().wait().tap().type(username),
            find(\.secureTextFields).placeholder(containing: "password").first().wait().tap().type(password),
            find(\.buttons).containing("Login").first().tap()
        )
    }

    func forgotPassword() -> TestStep<Login.Type> {
        find(\.buttons).containing("Forgot password").first().wait().tap().haunt()
    }
}

enum Dashboard: TestStepScreen {}
extension TestStep where Result == Dashboard.Type {

    func acceptOnboarding() -> Self {
        find(\.buttons).containing("Okay").first().tap().haunt()
    }

    func showSettings() -> TestStep<Settings.Type> {
        find(\.buttons).containing("Settings").first().tap().haunt()
    }
}

enum Settings: TestStepScreen {}

enum LoginScreen {}
enum DashboardScreen {}
enum SettingsScreen {}
extension TestStep where Result == LoginScreen.Type {
    func login(email: String, password: String) -> TestStep<DashboardScreen.Type> {
        find(\.textFields).placeholder(containing: "email").first().wait().tap().type(email)
            .then(find(\.secureTextFields).placeholder(containing: "password").first().tap().type(password))
            .then(find(\.buttons).containing("Login").first().tap())
            .haunt()
    }
}

extension TestStep where Result == DashboardScreen.Type {
    func openSettings() -> TestStep<SettingsScreen.Type> {
        find(\.buttons).containing("Settings").first().wait().tap().haunt()
    }
}
