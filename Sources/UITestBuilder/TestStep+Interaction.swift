//
//  TestStep+Interaction.swift
//  
//
//  Created by Max Godfrey on 1/08/21.
//

import XCTest

public extension TestStep where Result == AnnotatedElement {
    
    func exists(_ file: StaticString = #filePath, _ line: UInt = #line) -> Self {
        flatMap { element in
            if element.element.exists {
                return .always(element)
            }
            return .fail(TestStepError(.elementDoesNotExist(element: element), file: file, line: line))
        }
    }
    
    func exists(_ file: StaticString = #filePath, _ line: UInt = #line) -> TestStep<Void> {
        let result: Self = exists(file, line)
        return result.toVoidStep()
    }
    
    func wait(for timeout: TimeInterval = Defaults.timeout, _ file: StaticString = #filePath, _ line: UInt = #line) -> Self {
        flatMap { element in
            element.element.waitForExistence(timeout: timeout) ?
                .always(element) :
                .fail(TestStepError(.timedOutWaitingFor(element: element), file: file, line: line))
        }
    }
    
    func tap(_ file: StaticString = #filePath, _ line: UInt = #line) -> Self {
        exists(file, line)
            .do { $0.element.tap() }
    }
    
    func tap(_ file: StaticString = #filePath, _ line: UInt = #line) -> TestStep<Void> {
        let result: Self = tap(file, line)
        return result.toVoidStep()
    }
    
    func doubleTap(_ file: StaticString = #filePath, _ line: UInt = #line) -> Self {
        exists(file, line)
            .do(sideEffects: { $0.element.tap() })
    }
    
    func doubleTap(_ file: StaticString = #filePath, _ line: UInt = #line) -> TestStep<Void> {
        let result: Self = doubleTap(file, line)
        return result.toVoidStep()
    }
    
    func type(_ text: String, _ file: StaticString = #filePath, _ line: UInt = #line) -> Self {
        exists(file, line)
            .zip(.init(run: { app in
                AnnotatedElement(queryType: .keyboard, element: app.keyboards.element)
            }).exists(file, line))
            .map(\.0)
            .do { $0.element.typeText(text) }
    }
    
    func type(_ text: String, _ file: StaticString = #filePath, _ line: UInt = #line) -> TestStep<Void> {
        let result: Self = type(text, file, line)
        return result.toVoidStep()
    }
    
    func drag(to other: Self, pressDuration: TimeInterval = 0.2) -> TestStep<Void> {
        zip(other)
            .do { $0.0.element.press(forDuration: pressDuration, thenDragTo: $0.1.element) }
            .toVoidStep()
    }
    
    func swipe(_ direction: SwipeDirection, velocity: XCUIGestureVelocity? = nil) -> Self {
        self.do {
            $0.element.swipe(direction, velocity: velocity)
        }
    }
    
    func swipe(_ direction: SwipeDirection, velocity: XCUIGestureVelocity? = nil) -> TestStep<Void> {
        let result: Self = swipe(direction, velocity: velocity)
        return result.toVoidStep()
    }
}
