//
//  TestStep+Interaction.swift
//
//
//  Created by Max Godfrey on 1/08/21.
//

import XCTest

/// Functions that operate on `AnnotatedElement`s.
extension TestStep where Result == AnnotatedElement {

    /// If the Element exists the Test execution continues, otherwise fails with an `TestStepError.elementDoesNotExist`.
    /// - Returns: A TestStep that fails when the current element doesn't exist, if it does exist, a test step operating on the supplied value
    /// - Note: Ensure you wait before calling this if needed.
    public func exists(_ file: StaticString = #filePath, _ line: UInt = #line) -> Self {
        flatMap { element in
            if element.element.exists {
                return .always(element)
            }
            return .fail(TestStepError(.elementDoesNotExist(element: element), file: file, line: line))
        }
    }

    /// Variant of TestStep.exists(_:_:) that returns `Void`. Useful for when you want to assert an element exists without performing further actions upon it.
    public func exists(_ file: StaticString = #filePath, _ line: UInt = #line) -> TestStep<Void> {
        let result: Self = exists(file, line)
        return result.toVoidStep()
    }

    /// Waits for an element to exist for the supplied timeout, failing if it does not exist within that timeline.
    /// - Parameters:
    ///   - timeout: The time to poll the element while waiting for it to exist.
    /// - Returns: A TestStep that continues execution if the element exists, otherwise fails.
    public func wait(for timeout: TimeInterval = Defaults.timeout, _ file: StaticString = #filePath, _ line: UInt = #line) -> Self {
        flatMap { element in
            element.element.waitForExistence(timeout: timeout) ? .always(element) : .fail(TestStepError(.timedOutWaitingFor(element: element), file: file, line: line))
        }
    }

    /// Waits for the element to enable.
    /// - Parameters:
    ///   - timeout: The time to poll the element while waiting for it to exist.
    /// - Returns: A TestStep that continues execution if the element to enable.
    /// - Note: An element being enabled implies existence.
    public func waitToEnable(for timeout: TimeInterval = Defaults.timeout, _ file: StaticString = #filePath, _ line: UInt = #line) -> Self {
        wait(for: timeout, forPredicate: .enabled)
    }

    /// Wait for an element to fufil the predicate for the supplied timeout.
    /// - Parameters:
    ///   - timeout: The time to poll while waiting for the predicate to be fufilled.
    ///   - predicate: The predicate to wait for fufillment.
    /// - Returns: A TestStep that continues execution if the predicate is fufilled within the supplied timeinterval, otherwise a failing TestStep.
    public func wait(for timeout: TimeInterval = Defaults.timeout, forPredicate predicate: NSPredicate, _ file: StaticString = #filePath, _ line: UInt = #line) -> Self {
        flatMap { element in
            let waiter = XCTWaiter()
            let result = waiter.wait(for: [XCTNSPredicateExpectation(predicate: predicate, object: element)], timeout: timeout)
            switch result {
            case .completed:
                return .always(element)
            default:
                return .fail(TestStepError(.timedOutWaitingFor(element: element), file: file, line: line))
            }
        }
    }

    /// A TestStep that taps the element if it's exists.
    /// - Returns: A TestStep that continues execution if it exists, and after tapping the element, otherwise if it doesn't exist a failing TestStep.
    public func tap(_ file: StaticString = #filePath, _ line: UInt = #line) -> Self {
        exists(file, line)
            .do { $0.element.tap() }
    }

    /// A variant of TestStep.tap(_:_:) that discards it's contents.  Useful for when you want to assert an element exists without performing further actions upon it.
    public func tap(_ file: StaticString = #filePath, _ line: UInt = #line) -> TestStep<Void> {
        let result: Self = tap(file, line)
        return result.toVoidStep()
    }

    /// A TestStep that double taps the element if it's exists.
    /// - Returns: A TestStep that continues execution if it exists, and after double tapping the element, otherwise if it doesn't exist a failing TestStep.
    public func doubleTap(_ file: StaticString = #filePath, _ line: UInt = #line) -> Self {
        exists(file, line)
            .do(sideEffects: { $0.element.doubleTap() })
    }

    /// A variant of TestStep.doubleTap(_:_:) that discards it's contents.  Useful for when you want to assert an element exists without performing further actions upon it.
    public func doubleTap(_ file: StaticString = #filePath, _ line: UInt = #line) -> TestStep<Void> {
        let result: Self = doubleTap(file, line)
        return result.toVoidStep()
    }

    /// A TestStep that types within the element, if it exists.
    /// - Important: Ensure the element has focus before you attempt to type!
    /// - Parameters:
    ///   - text: Text to type.
    /// - Returns: A TestStep that continue execution if the element exists
    public func type(_ text: String, _ file: StaticString = #filePath, _ line: UInt = #line) -> Self {
        exists(file, line)
            .zip(
                find(\.keyboards).first().exists(file, line)
            )
            .map { (element: (AnnotatedElement, Void)) -> AnnotatedElement in
                element.0
            }
            .do { $0.element.typeText(text) }
    }

    public func type(_ text: String, _ file: StaticString = #filePath, _ line: UInt = #line) -> TestStep<Void> {
        let result: Self = type(text, file, line)
        return result.toVoidStep()
    }

    public func drag(to other: Self, pressDuration: TimeInterval = 0.2) -> TestStep<Void> {
        zip(other)
            .do { $0.0.element.press(forDuration: pressDuration, thenDragTo: $0.1.element) }
            .toVoidStep()
    }

    public func swipe(_ direction: SwipeDirection, velocity: XCUIGestureVelocity? = nil) -> Self {
        self.do {
            $0.element.swipe(direction, velocity: velocity)
        }
    }

    public func swipe(_ direction: SwipeDirection, velocity: XCUIGestureVelocity? = nil) -> TestStep<Void> {
        let result: Self = swipe(direction, velocity: velocity)
        return result.toVoidStep()
    }
}
