//
//  TestStep.swift
//  
//
//  Created by Max Godfrey on 1/08/21.
//

import XCTest

/// A step of execution in a Test. Allows us to compose a test from smaller units.
/// - Discussion:
/// `TestStep<Void>` is the backing representation for the `UITestBuilder`result builder.
/// You can lift XCUIElement queries into a TestStep via `find(_:)`.
public struct TestStep<Result> {
    let run: (XCUIElement) throws -> Result
    
    public func callAsFunction(_ app: XCUIApplication) throws -> Result {
        try self.run(app)
    }
}

public extension TestStep {
    
    /// Creates a TestStep that always fails with the supplied Error.
    /// This is useful when you want to cause a test to fail based on some input.
    /// In practice you can use existing combinators without having to reach for these TestSteps.
    ///
    /// For example if you wanted to ensure that, without waiting there is at least one button on screen you can::
    /// ```
    /// find(\.buttons)
    ///     .flatMap { (elementQuery: XCUIElementQuery) in
    ///         if elementQuery.count < 1 {
    ///             return .fail(TestStepError.noElementsFoundMatchingQuery(elementQuery))
    ///         }
    ///         return .always(elementQuery)
    ///     }
    /// ```
    /// - Parameter error: The Error to fail the test with.
    /// - Returns: A TestStep that always fails.
    static func fail(_ error: Error) -> TestStep { TestStep { _ in throw error } }
    
    /// Creates a TestStep that continues with the supplied value..
    /// This is useful when you want to allow a test to continue in some case, but fail in another. Also see  `static TestStep.fail(_:)`.
    /// In practice you can use existing combinators without having to reach for these TestSteps.
    ///
    /// For example if you wanted to ensure that, without waiting there is at least one button on screen you can::
    /// ```
    /// find(\.buttons)
    ///     .flatMap { (elementQuery: XCUIElementQuery) -> TestStep<XCUIElementQuery> in
    ///         if elementQuery.count < 1 {
    ///             return .fail(TestStepError.noElementsFoundMatchingQuery(elementQuery))
    ///         }
    ///         return .always(elementQuery)
    ///     }
    /// ```
    /// - Parameter error: The value to continue the test with.
    /// - Returns: A TestStep that passes the supplied value on.
    static func always(_ value: Result) -> TestStep { TestStep { _ in value } }
}

/// Standard entry point into creating XCUIElementQueries. Allows you to lift a supplied function into a TestStep. This provides a consistent way of describing where to find an element,
/// deferring the __actual__ finding till the test is run.
/// - Parameter query: A function from element to query. This is intended so you can lean on KeyPaths for a nicer shorthand  e.g. `find(\.buttons.staticTexts)`.
/// - Returns: The supplied query lifted into a composable TestStep. See `extension TestStep where Result == XCUIElement {` for avaliable usages.
public func find(_ query: @escaping (XCUIElement) -> XCUIElementQuery) -> TestStep<XCUIElementQuery> {
    TestStep<XCUIElementQuery>(run: query)
}

public enum Either<A, B> {
    case left(A)
    case right(B)
}

public extension TestStep {
    
    func map<B>(_ f: @escaping (Result) -> B) -> TestStep<B> {
        TestStep<B> { app in
            try f(self.run(app))
        }
    }
    
    func flatMap<B>(_ f: @escaping (Result) -> TestStep<B>) -> TestStep<B> {
        TestStep<B> { app in
            let resA = try run(app)
            let stepB = f(resA)
            let resB = try stepB.run(app)
            return resB
        }
    }
    
    func zip<B>(_ otherStep: TestStep<B>) -> TestStep<(Result, B)> {
        TestStep<(Result, B)> { app in
            let a = try self.run(app)
            let b = try otherStep.run(app)
            return (a, b)
        }
    }
    
    func zip<B, C>(_ b: TestStep<B>, _ c: TestStep<C>) -> TestStep<(Result, B, C)> {
        .init { app in
            let a = try self.run(app)
            let b = try b.run(app)
            let c = try c.run(app)
            return (a, b, c)
        }
    }
    
    func zip<B, C, D>(_ b: TestStep<B>, _ c: TestStep<C>, _ d: TestStep<D>) -> TestStep<(Result, B, C, D)> {
        .init { app in
            let a = try self.run(app)
            let b = try b.run(app)
            let c = try c.run(app)
            let d = try d.run(app)
            return (a, b, c, d)
        }
    }
    
    func zip<B, C, D, E>(_ c0: TestStep<B>, _ c1: TestStep<C>, _ c2: TestStep<D>, _ c3: TestStep<E>) -> TestStep<(Result, B, C, D, E)> {
        self.zip(c0, c1, c2).zip(c3).map { ($0.0.0, $0.0.1, $0.0.2, $0.0.3, $0.1) }
    }
    
    /// Run the receivers test step, and if it fails, then fallback to the supplied `otherStep`
    func orElse<B>(_ otherStep: TestStep<B>) -> TestStep<Either<Result, B>> {
        .init { app in
            do {
                return Either<Result, B>.left(try self.run(app))
            } catch {
                return Either<Result, B>.right(try otherStep.run(app))
            }
        }
    }
    
    func orElse(_ otherStep: TestStep<Result>) -> TestStep<Result> {
        .init { app in
            do {
                return try self.run(app)
            } catch {
                return try otherStep.run(app)
            }
        }
    }
    
    func optional() -> TestStep<Result?> {
        TestStep<Result?> { app in
            try? self.run(app)
        }
    }
    
    func debug() -> Self {
        self.do { result in
            raise(SIGINT)
        }
    }
    
    func `do`(sideEffects f: @escaping (Result) -> Void) -> Self {
        .init { app in
            let output = try self.run(app)
            f(output)
            return output
        }
    }
    
    func printResult(prefix: String = "") -> Self {
        self.do {
            print("\(prefix)\($0)")
        }
    }
}
