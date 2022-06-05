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

extension TestStep {

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
    public static func fail(_ error: Error) -> Self { TestStep { _ in throw error } }

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
    public static func always(_ value: Result) -> Self { TestStep { _ in value } }
}

/// Standard entry point into creating XCUIElementQueries. Allows you to lift a supplied function into a TestStep. This provides a consistent way of describing where to find an element,
/// deferring the __actual__ finding till the test is run.
/// - Parameter query: A function from element to query. This is intended so you can lean on KeyPaths for a nicer shorthand  e.g. `find(\.buttons.staticTexts)`.
/// - Returns: The supplied query lifted into a composable TestStep. See `extension TestStep where Result == XCUIElement {` for avaliable usages.
public func find(_ query: @escaping (XCUIElement) -> XCUIElementQuery) -> TestStep<XCUIElementQuery> {
    TestStep<XCUIElementQuery>(run: query)
}

/// Convience for starting a step in a test, for when you don't care about the specific element, but you want to perform a test step interaction.
/// Note you can only trigger interactions that can't fail
/// For instance, to swipe up on the screen,
/// ```
/// screen()
///     .swipeUp()
/// ```
/// - Returns:
public func screen() -> TestStep<XCUIElement> {
    TestStep { $0 }
}

public enum Either<A, B> {
    case left(A)
    case right(B)
}

extension TestStep {

    /// An operator that transforms the Result of the receiver by applying the supplied transformation closure `f`.
    /// This allows the Result to be transformed preserving the context (TestStep).
    /// - Parameter f: The function to apply to the current result of the TestStep, assuming it hasn't failed prior.
    /// - Returns: A TestStep with it's Result transformed into `B`.
    public func map<B>(_ f: @escaping (Result) -> B) -> TestStep<B> {
        TestStep<B> { app in
            try f(self.run(app))
        }
    }

    /// An operator that transforms the Result of the receiver by applying the supplied transformation closure `f`.
    /// This allows the context (TestStep) to be transformed based on the current Result. This is a
    /// sequencing operator.
    ///
    /// - Parameter f: The function to apply to the current result to then form the new return TestStep.
    /// - Returns: A TestStep that is composed of the reciever's result and the supplied functions `f`result.
    public func flatMap<B>(_ f: @escaping (Result) -> TestStep<B>) -> TestStep<B> {
        TestStep<B> { app in
            let resA = try run(app)
            let stepB = f(resA)
            let resB = try stepB.run(app)
            return resB
        }
    }

    /// An operator that runs both the receiver and the supplied `otherStep`, I.f.f. the result of both of these is successful will
    /// the resulting TestStep continue.
    /// - Parameter otherStep: The  TestStep to run affter the reciever (if it is successul).
    /// - Returns: A TestStep that holds the Results of both the reciever and the supplied `otherStep`.
    public func zip<B>(_ otherStep: TestStep<B>) -> TestStep<(Result, B)> {
        TestStep<(Result, B)> { app in
            let a = try self.run(app)
            let b = try otherStep.run(app)
            return (a, b)
        }
    }

    /// A variant of `TestStep.zip(_:)` that allow two diffferent steps.
    public func zip<B, C>(_ b: TestStep<B>, _ c: TestStep<C>) -> TestStep<(Result, B, C)> {
        .init { app in
            let a = try self.run(app)
            let b = try b.run(app)
            let c = try c.run(app)
            return (a, b, c)
        }
    }

    /// A variant of `TestStep.zip(_:)` that allow three diffferent steps.
    public func zip<B, C, D>(_ b: TestStep<B>, _ c: TestStep<C>, _ d: TestStep<D>) -> TestStep<
        (Result, B, C, D)
    > {
        .init { app in
            let a = try self.run(app)
            let b = try b.run(app)
            let c = try c.run(app)
            let d = try d.run(app)
            return (a, b, c, d)
        }
    }

    /// A variant of `TestStep.zip(_:)` that allow four diffferent steps.
    public func zip<B, C, D, E>(
        _ c0: TestStep<B>,
        _ c1: TestStep<C>,
        _ c2: TestStep<D>,
        _ c3: TestStep<E>
    ) -> TestStep<(Result, B, C, D, E)> {
        self.zip(c0, c1, c2).zip(c3).map { ($0.0.0, $0.0.1, $0.0.2, $0.0.3, $0.1) }
    }

    /// Run the receivers Test Step and if it fails, then fallback to the supplied  `otherStep`.
    /// - Parameter otherStep: The TestStep to try if the reciever fails.
    /// - Returns: A TestStep holding an `Either` of the Result of the reciever, if it succeeded otherwise the `otherStep` if that succeeded.
    public func orElse<B>(_ otherStep: TestStep<B>) -> TestStep<Either<Result, B>> {
        .init { app in
            do {
                return Either<Result, B>.left(try self.run(app))
            } catch {
                return Either<Result, B>.right(try otherStep.run(app))
            }
        }
    }

    /// Run the receivers Test Step and if it fails, then fallback to the supplied  `otherStep` that is of the same resulting type as `self`
    /// - Parameter otherStep: The TestStep to try if the reciever fails.
    /// - Returns: A TestStep holding the Result of the reciever, if it succeeded otherwise the `otherStep` if that succeeded.
    public func orElse(_ otherStep: TestStep<Result>) -> TestStep<Result> {
        .init { app in
            do {
                return try self.run(app)
            } catch {
                return try otherStep.run(app)
            }
        }
    }

    /// An operator that swallows the TestStep's error if it fails, instead feeding an optional Result through.
    /// - Returns: A TestStep with it's Result lifted into Optional.
    public func optional() -> TestStep<Result?> {
        TestStep<Result?> { app in
            try? self.run(app)
        }
    }

    /// An operator to perform side effects based on the current Result.
    /// - Parameter work: A function where you can perform side effects.
    /// - Returns: A TestStep with the same result that was fed in (but with side effects having being run).
    public func `do`(sideEffects work: @escaping (Result) -> Void) -> Self {
        .init { app in
            let output = try self.run(app)
            work(output)
            return output
        }
    }

    /// Triggers a breakpoint in Debug build configurations, allowing you to inspect the call stack, variables etc.
    /// - Returns: The supplied TestStep but with a breakpoint occuring after it's run.
    public func breakpoint() -> Self {
        #if DEBUG
            self.do { result in
                raise(SIGINT)
            }
        #endif
    }

    /// Print's the current Result
    /// - Parameter prefix: A prefix to apply for easier debugging.
    /// - Returns: The supplied TestStep but with a print side effect occuring after it's run.
    public func printResult(prefix: String = "") -> Self {
        self.do {
            print("\(prefix)\($0)")
        }
    }

    /// Convienence function to take any `TestStep` and ignore it's output, resulting in a `TestStep<Void>`
    /// - Returns: A TestStep that ignores the output.
    public func toVoidStep() -> TestStep<Void> {
        map { _ in }
    }
}
