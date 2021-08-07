//
//  XCTest+Extensions.swift
//  
//
//  Created by Max Godfrey on 7/08/21.
//

import XCTest

public enum SwipeDirection {
    case left, right, up, down
}

extension XCUIElement {
    
    func swipe(_ direction: SwipeDirection, velocity: XCUIGestureVelocity? = nil) {
        switch direction {
        case .left:
            return velocity.map { swipeLeft(velocity: $0) } ?? swipeLeft()
        case .right:
            return velocity.map { swipeRight(velocity: $0) } ?? swipeRight()
        case .up:
            return velocity.map { swipeUp(velocity: $0) } ?? swipeUp()
        case .down:
            return velocity.map { swipeDown(velocity: $0) } ?? swipeDown()
        }
    }
}
