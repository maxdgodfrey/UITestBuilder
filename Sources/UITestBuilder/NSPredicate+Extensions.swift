//
//  NSPredicate+Extensions.swift
//
//
//  Created by Max Godfrey on 1/08/21.
//

import Foundation

extension NSPredicate {
    public static func containsIgnoringCase(property: String, value: String) -> NSPredicate {
        NSPredicate(format: "\(property) CONTAINS[c] %@", value)
    }

    public static func labelContains(value: String) -> NSPredicate {
        containsIgnoringCase(property: "label", value: value)
    }

    public static func placeholderContains(value: String) -> NSPredicate {
        containsIgnoringCase(property: "placeholderValue", value: value)
    }

    public static var enabled: NSPredicate {
        NSPredicate(format:"enabled == true")
    }

    public static var disabled: NSPredicate {
        NSPredicate(format:"enabled == false")
    }
}
