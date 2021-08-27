//
//  TestStep+Interaction.swift
//
//
//  Created by Max Godfrey on 1/08/21.
//

import XCTest

extension TestStep where Result == AnnotatedElement {

    public func exists(_ file: StaticString = #filePath, _ line: UInt = #line) -> Self {
        flatMap { element in
            if element.element.exists {
                return .always(element)
            }
            return .fail(TestStepError(.elementDoesNotExist(element: element), file: file, line: line))
        }
    }

    public func exists(_ file: StaticString = #filePath, _ line: UInt = #line) -> TestStep<Void> {
        let result: Self = exists(file, line)
        return result.toVoidStep()
    }

    public func wait(for timeout: TimeInterval = Defaults.timeout, _ file: StaticString = #filePath, _ line: UInt = #line) -> Self {
        flatMap { element in
            element.element.waitForExistence(timeout: timeout) ? .always(element) : .fail(TestStepError(.timedOutWaitingFor(element: element), file: file, line: line))
        }
    }

    public func tap(_ file: StaticString = #filePath, _ line: UInt = #line) -> Self {
        exists(file, line)
            .do { $0.element.tap() }
    }

    public func tap(_ file: StaticString = #filePath, _ line: UInt = #line) -> TestStep<Void> {
        let result: Self = tap(file, line)
        return result.toVoidStep()
    }

    public func doubleTap(_ file: StaticString = #filePath, _ line: UInt = #line) -> Self {
        exists(file, line)
            .do(sideEffects: { $0.element.tap() })
    }

    public func doubleTap(_ file: StaticString = #filePath, _ line: UInt = #line) -> TestStep<Void> {
        let result: Self = doubleTap(file, line)
        return result.toVoidStep()
    }

    public func type(_ text: String, _ file: StaticString = #filePath, _ line: UInt = #line) -> Self {
        exists(file, line)
            .zip(
                .init(run: { app in
                    AnnotatedElement(queryType: .keyboard, element: app.keyboards.element)
                })
                .exists(file, line)
            )
            .map(\.0)
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
