//
//  XCUIApplication+Interaction.swift
//  
//
//  Created by Max Godfrey on 7/08/21.
//

import XCTest

public extension TestStep where Result == XCUIApplication {
    
    func swipe(_ direction: SwipeDirection, velocity: XCUIGestureVelocity? = nil) -> TestStep<Void> {
        self.do { app in
            app.swipe(direction, velocity: velocity)
        }.toVoidStep()
    }
    
    func tap() -> TestStep<Void> {
        self.do { app in
            app.tap()
        }.toVoidStep()
    }
    
    func doubleTap() -> TestStep<Void> {
        self.do { app in
            app.doubleTap()
        }.toVoidStep()
    }
    
    func rotate(_ rotation: CGFloat, withVelocity velocity: CGFloat) -> TestStep<Void> {
        self.do { app in
            app.rotate(rotation, withVelocity: velocity)
        }.toVoidStep()
    }
    
    func press(for duration: TimeInterval) -> TestStep<Void> {
        self.do { app in
            app.press(forDuration: duration)
        }.toVoidStep()
    }
}
