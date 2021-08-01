//
//  QueryResults.swift
//  
//
//  Created by Max Godfrey on 1/08/21.
//

import XCTest

public struct AnnotatedElement {
    let queryType: QueryType
    public let element: XCUIElement
}

public struct AnnotatedQuery {
    let type: QueryType
    public let query: XCUIElementQuery
}

public indirect enum QueryType: CustomStringConvertible {
    case boundBy(Int)
    case matching(String)
    case matchingIdentifier(String)
    case matchingPredicate(String)
    case onlyElement(QueryType)
    case keyboard
    
    public var description: String {
        switch self {
        case let .boundBy(index):
            return "Bound by \(index)"
        case let .matching(value):
            return "Matching \(value)"
        case let .matchingPredicate(format):
            return "Matching predicate with format: \(format)"
        case let .onlyElement(queryType):
            return "Only element of \(queryType.description)"
        case .keyboard:
            return "Keyboard wasn't displayed! Ensure that \"Connect Hardware Keyboard\" is disabled under: \"Simulator > IO > Keyboard > Connect Hardware Keyboard\""
        case let .matchingIdentifier(identifier):
            return "Matching accessibility identifier \(identifier)"
        }
    }
}

public struct TestStepError: CustomStringConvertible, Error {
    
    enum Error: CustomStringConvertible {
        case unexpectedNumberOfElementsMatching(query: AnnotatedQuery, expected: Int, got: Int)
        case timedOutWaitingFor(element: AnnotatedElement)
        case elementDoesNotExist(element: AnnotatedElement)
        case assertionFailed
        
        var description: String {
            switch self {
            case let .unexpectedNumberOfElementsMatching(query, expected, got):
                return "🚫 Expected \(expected) instances of \(query), instead got \(got)."
            case let .timedOutWaitingFor(element):
                return """
                       ⏰ Timed out waiting for element!
                           * Element: \(element)
                           * Query: \(element.queryType.description)
                       """
            case let .elementDoesNotExist(element):
                // TODO: Change this message. We can't wait before executing the predicate, we wait after!
                return  """
                        👻 Element doesn't exist, are you sure it's on screen?
                           * Check out the `Element` section below above to see what the query chain was
                           * Element: \(element.element)
                           * Predicate: \(element.queryType.description)
                           
                           * Try
                              - Adding a `.wait(_:)` call before trying to interact with the element
                              - Loosening your predicate. Could you use a `contains: text` variant if not using already.
                        """
            case .assertionFailed:
                return "🛑 Assertion failed."
            }
        }
    }
    
    init(_ type: Error, file: StaticString = #file, line: UInt = #line) {
        self.type = type
        self.file = file
        self.line = line
    }
    
    let type: Error
    public let file: StaticString
    public let line: UInt
    
    public var description: String {
        type.description
    }
}
