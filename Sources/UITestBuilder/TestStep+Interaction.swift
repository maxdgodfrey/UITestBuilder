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
        return result.map { _ in }
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
        return result.map { _ in }
    }
    
    func doubleTap(_ file: StaticString = #filePath, _ line: UInt = #line) -> Self {
        exists(file, line)
            .do(sideEffects: { $0.element.tap() })
    }
    
    func doubleTap(_ file: StaticString = #filePath, _ line: UInt = #line) -> TestStep<Void> {
        let result: Self = doubleTap(file, line)
        return result.map { _ in }
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
        return result.map { _ in }
    }
    
    func drag(to other: Self) -> TestStep<Void> {
        zip(other)
            .do { $0.0.element.press(forDuration: 0.2, thenDragTo: $0.1.element) }
            .map { _ in }
    }
    
    enum SwipeDirection {
        case left, right, up, down
    }
    
    func swipe(_ direction: SwipeDirection, velocity: XCUIGestureVelocity? = nil) -> Self {
        self.do {
            let element = $0.element
            switch direction {
            case .left:
                return velocity.map { element.swipeLeft(velocity: $0) } ?? element.swipeLeft()
            case .right:
                return velocity.map { element.swipeRight(velocity: $0) } ?? element.swipeRight()
            case .up:
                return velocity.map { element.swipeUp(velocity: $0) } ?? element.swipeUp()
            case .down:
                return velocity.map { element.swipeDown(velocity: $0) } ?? element.swipeDown()
            }
        }
    }
    
    func swipe(_ direction: SwipeDirection, velocity: XCUIGestureVelocity? = nil) -> TestStep<Void> {
        let result: Self = swipe(direction, velocity: velocity)
        return result.map { _ in }
    }
}
