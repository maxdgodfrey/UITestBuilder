//
//  Experimental.swift
//
//
//  Created by Max Godfrey on 1/08/21.
//

import Foundation
import XCTest

// MARK: - Phantom Type Screen Object Support

extension TestStep where Result == Void {
    public func haunt<T>() -> TestStep<T.Type> {
        map { T.self }  // Void -> Phantomable
    }

    public func then(_ other: TestStep<Void>) -> TestStep<Void> {
        zip(other).toVoidStep()
    }
}

/// Semantic protocol allowing you to convienently start a test from a Screen type
/// For example given a Login Screen type
/// ```
///     enum LoginScreen {}
///     enum DashboardScreen {}
///     extension TestStep where Result == LoginScreen.Type {
///         func login(email: String, password: String) -> TestStep<DashboardScreen.Type> {
///             find(\.textFields).placeholder(containing: "email").first().wait().tap().type(email)
///                 .then(find(\.secureTextFields).placeholder(containing: "password").first().tap().type(password))
///                 .then(find(\.buttons).containing("Login").first().tap())
///                 .haunt()
///         }
///     }
///
///     extension TestStep where Result == DashboardScreen.Type {
///         func openSettings() -> TestStep<SettingsScreen.Type> { /* omitted for brevity */ }
///     }
/// ```
/// In your test you can go:
/// ```
///     func testLogin() {
///         LoginScreen.start()
///             .login(email: "foo@bar.com", password: "baz")
///             .openSettings()
///     }
/// ```
public protocol TestStepScreen {}
extension TestStepScreen {
    public static func start() -> TestStep<Self.Type> {
        .init { _ in
            self
        }
    }
}

func haunt<T>(@UITestBuilder testBuilder: () -> TestStep<Void>) -> TestStep<T.Type> {
    testBuilder().haunt()
}

public func steps<T>(_ steps: TestStep<Void>...) -> TestStep<T.Type> {
    steps.reduce(TestStep { _ in () }) { current, next in
        current.zip(next).toVoidStep()
    }
    .haunt()
}

extension UITestBuilder {

    public static func buildBlock<Phantom>(_ components: TestStep<Void>...) -> TestStep<Phantom.Type> {
        let house = TestStep<Void> { app in
            for comp in components {
                try comp.run(app)
            }
        }
        return house.haunt()
    }
}
