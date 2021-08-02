//
//  NSPredicate+Extensions.swift
//  
//
//  Created by Max Godfrey on 1/08/21.
//

import Foundation

public extension NSPredicate {
    static func containsIgnoringCase(property: String, value: String) -> NSPredicate {
        NSPredicate(format: "\(property) CONTAINS[c] %@", value)
    }
    
    static func labelContains(value: String) -> NSPredicate {
        containsIgnoringCase(property: "label", value: value)
    }
    
    static func placeholderContains(value: String) -> NSPredicate {
        containsIgnoringCase(property: "placeholderValue", value: value)
    }
}
