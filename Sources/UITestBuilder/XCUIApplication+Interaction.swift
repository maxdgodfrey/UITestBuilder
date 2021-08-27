//
//  XCUIApplication+Interaction.swift
//
//
//  Created by Max Godfrey on 7/08/21.
//

import XCTest

extension TestStep where Result == XCUIApplication {

    public func swipe(_ direction: SwipeDirection, velocity: XCUIGestureVelocity? = nil)
        -> TestStep<
            Void
        >
    {
        self.do { app in
            app.swipe(direction, velocity: velocity)
        }.toVoidStep()
    }

    public func tap() -> TestStep<Void> {
        self.do { app in
            app.tap()
        }.toVoidStep()
    }

    public func doubleTap() -> TestStep<Void> {
        self.do { app in
            app.doubleTap()
        }.toVoidStep()
    }

    public func rotate(_ rotation: CGFloat, withVelocity velocity: CGFloat) -> TestStep<Void> {
        self.do { app in
            app.rotate(rotation, withVelocity: velocity)
        }.toVoidStep()
    }

    public func press(for duration: TimeInterval) -> TestStep<Void> {
        self.do { app in
            app.press(forDuration: duration)
        }.toVoidStep()
    }
}
