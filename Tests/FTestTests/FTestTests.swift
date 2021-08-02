import XCTest
@testable import FTest
    
final class FTestTests: XCTestCase {
     
    enum TestError: Error {
        case `default`
    }
    
    func testMap() throws {
        let testStep = TestStep<Int>(run: { _ in 1 })
        let mapped = testStep.map(String.init)

        let output = try mapped.run(XCUIElement())
        XCTAssertEqual(output, "1")
    }
    
    func testMap_fail() throws {
        let testStep = TestStep<Int>(run: { _ in 1 })
        let fail: TestStep<Int> = testStep.flatMap { _ in .never(TestError.default) }
        let mapped = fail.map(String.init)
        
        XCTAssertThrowsError(try mapped(XCUIApplication(bundleIdentifier: "abc")))
    }
}
