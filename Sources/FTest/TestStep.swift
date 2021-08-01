//
//  TestStep.swift
//  
//
//  Created by Max Godfrey on 1/08/21.
//

import XCTest

public struct TestStep<Result> {
    let run: (XCUIElement) throws -> Result
    
    public func callAsFunction(_ app: XCUIApplication) throws -> Result {
        try self.run(app)
    }
}

public extension TestStep {
    static func never(_ a: Error) -> TestStep { TestStep { _ in throw a } }
    static func always(_ a: Result) -> TestStep { TestStep { _ in a } }
}

public enum Either<A, B> {
    case left(A)
    case right(B)
}

public extension TestStep {
    
    func map<B>(_ f: @escaping (Result) -> B) -> TestStep<B> {
        TestStep<B> { app in
            try f(self.run(app))
        }
    }
    
    func flatMap<B>(_ f: @escaping (Result) -> TestStep<B>) -> TestStep<B> {
        TestStep<B> { app in
            let resA = try run(app)
            let stepB = f(resA)
            let resB = try stepB.run(app)
            return resB
        }
    }
    
    func zip<B>(_ otherStep: TestStep<B>) -> TestStep<(Result, B)> {
        TestStep<(Result, B)> { app in
            let a = try self.run(app)
            let b = try otherStep.run(app)
            return (a, b)
        }
    }
    
    func zip<B, C>(_ b: TestStep<B>, _ c: TestStep<C>) -> TestStep<(Result, B, C)> {
        .init { app in
            let a = try self.run(app)
            let b = try b.run(app)
            let c = try c.run(app)
            return (a, b, c)
        }
    }
    
    func zip<B, C, D>(_ b: TestStep<B>, _ c: TestStep<C>, _ d: TestStep<D>) -> TestStep<(Result, B, C, D)> {
        .init { app in
            let a = try self.run(app)
            let b = try b.run(app)
            let c = try c.run(app)
            let d = try d.run(app)
            return (a, b, c, d)
        }
    }
    
    func zip<C0, C1, C2, C3>(_ c0: TestStep<C0>, _ c1: TestStep<C1>, _ c2: TestStep<C2>, _ c3: TestStep<C3>) -> TestStep<(Result, C0, C1, C2, C3)> {
        self.zip(c0, c1, c2).zip(c3).map { ($0.0.0, $0.0.1, $0.0.2, $0.0.3, $0.1) }
    }
    
    /// Run the receivers test step, and if it fails, then fallback to the supplied `otherStep`
    func orElse<B>(_ otherStep: TestStep<B>) -> TestStep<Either<Result, B>> {
        .init { app in
            do {
                return Either<Result, B>.left(try self.run(app))
            } catch {
                return Either<Result, B>.right(try otherStep.run(app))
            }
        }
    }
    
    func orElse(_ otherStep: TestStep<Result>) -> TestStep<Result> {
        .init { app in
            do {
                return try self.run(app)
            } catch {
                return try otherStep.run(app)
            }
        }
    }
    
    func optional() -> TestStep<Result?> {
        TestStep<Result?> { app in
            try? self.run(app)
        }
    }
}
