//
//  Convenience.swift
//
//
//  Created by Max Godfrey on 12/09/21.
//

import XCTest

public func test(application: XCUIApplication, @UITestBuilder testBuilder: () -> TestStep<Void>) {
    test(application: application, testBuilder())
}

public func test(application: XCUIApplication, _ step: TestStep<Void>) {
    do {
        try step(application)
    } catch {
        guard let error = error as? TestStepError else {
            XCTFail(error.localizedDescription)
            return
        }
        XCTFail(error.description, file: error.file, line: error.line)
    }
}
