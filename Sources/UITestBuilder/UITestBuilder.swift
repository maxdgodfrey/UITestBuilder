//
//  UITestBuilder.swift
//  
//
//  Created by Max Godfrey on 1/08/21.
//

import Foundation

@resultBuilder
public struct UITestBuilder {
    
    public static func buildBlock(_ components: TestStep<Void>...) -> TestStep<Void> {
        TestStep { app in
            for comp in components {
                try comp.run(app)
            }
        }
    }
}

extension TestStep {
    
    public init(@UITestBuilder steps: @escaping () -> TestStep<Result>) {
        self.init { app in
            try steps().run(app)
        }
    }
}
