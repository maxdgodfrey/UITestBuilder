//
//  Experimental.swift
//  
//
//  Created by Max Godfrey on 1/08/21.
//

import Foundation
import XCTest


// MARK: - Keyboard
#warning("Not sure this belongs in here")
public let dismissKeyboard: TestStep<Void> = find(\.keyboards.buttons).containing("return").onlyElement().tap()

#warning("Just experimenting with different syntaxes")
extension String {
    
    var buttons: TestStep<AnnotatedQuery> {
        find(.button).containing(self)
    }
    
    public func containing(for elementType: XCUIElement.ElementType) -> TestStep<AnnotatedQuery> {
        find(elementType).containing(self)
    }
}

extension XCUIElement.ElementType {
    
    func containing(text: String) -> TestStep<AnnotatedQuery> {
        find(queryFunction).containing(text)
    }
}

public extension TestStep where Result == Void {
    func haunt<T>() -> TestStep<T.Type> {
        map { T.self } // Void -> Phantomable
    }
    
    func then(_ other: TestStep<Void>) -> TestStep<Void> {
        zip(other).map { _ in }
    }
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
