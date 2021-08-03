//
//  Experimental.swift
//  
//
//  Created by Max Godfrey on 1/08/21.
//

import Foundation
import XCTest

// MARK: - Phantom Type Support

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
