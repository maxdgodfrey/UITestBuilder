import XCTest

public struct AnnotatedElement {
    let queryType: QueryType
    let element: XCUIElement
}

public struct AnnotatedQuery {
    let type: QueryType
    let query: XCUIElementQuery
    
    static func create(with type: QueryType) -> (XCUIElementQuery) -> Self {
        return { query in
            AnnotatedQuery.init(type: type, query: query)
        }
    }
}

public indirect enum QueryType: CustomStringConvertible {
    case boundBy(Int)
    case matching(String)
    case matchingPredicate(String)
    case onlyElement(QueryType)
    
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
        }
    }
}

public struct TestStepError: CustomStringConvertible, Error {

    enum Error: CustomStringConvertible {
        case unexpectedNumberOfElementsMatching(query: String, expected: Int, got: Int)
        case timedOutWaitingFor(element: AnnotatedElement)
        case elementDoesNotExist(element: AnnotatedElement)
        
        var description: String {
            switch self {
            case let .unexpectedNumberOfElementsMatching(query, expected, got):
                return "🚫 Expected \(expected) instances of \(query), instead got \(got)."
            case let .timedOutWaitingFor(element):
                return "⏰ Timed out waiting for element: \(element) using query \(element.queryType.description)."
            case let .elementDoesNotExist(element):
                return "👻 Element doesn't exist \(element.element) for predicate \(element.queryType.description). You may need to call `.wait(_:)` before trying to match. Or try a looser predicate like one of the `.contains(_:)` methods on TestStep."
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

func performAutoLogin(accessId: String, password: String) -> TestStep<Void> {
    TestStep<Void>.button(matching: "Start").wait().tap()
        .zip(.navigationBarTitle(matching: "Nav title").wait())
        .zip(.navigationButton(matching: "Start").tap())
        .zip(.firstTextfield(matching: "Access Id").wait().tap().type(accessId))
        .zip(.firstTextfield(matching: "Password").type(password))
        .zip(.button(matching: "Login").tap())
        .map { _ in }
}

public struct TestStep<Result> {
    #warning("Can update this to take the #file and #line!")
    let run: (XCUIApplication) throws -> Result
}

extension TestStep {
    
    public func callAsFunction(_ app: XCUIApplication) throws -> Result {
        try self.run(app)
    }
}

public extension TestStep {
    static func never(_ a: Error) -> TestStep { TestStep { _ in throw a } }
    static func always(_ a: Result) -> TestStep { TestStep { _ in a } }
}

public func flatMap<A, B>(_ f: @escaping (A) -> TestStep<B>) -> (TestStep<A>) -> TestStep<B> {
    return { testStep in
        TestStep<B> { app in
            let resA = try testStep.run(app)
            let stepB = f(resA)
            let resB = try stepB.run(app)
            return resB
        }
    }
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
        FTest.flatMap(f)(self)
    }
    
    func zip<B>(_ otherStep: TestStep<B>) -> TestStep<(Result, B)> {
        TestStep<(Result, B)> { app in
            let a = try self.run(app)
            let b = try otherStep.run(app)
            return (a, b)
        }
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
    
    /// Like `do` but you can start the sequence with it
    static func debug(_ f: @escaping (XCUIApplication) -> Void) -> TestStep<XCUIApplication> {
        .init { app in
            f(app)
            return app
        }
    }
}

public extension TestStep where Result == AnnotatedQuery {
    
    func boundBy(_ index: Int, _ file: StaticString = #filePath, _ line: UInt = #line) -> TestStep<AnnotatedElement> {
        self.map {
            let element = $0.query.element(boundBy: index)
            return AnnotatedElement(queryType: .boundBy(index), element: element)
        }
        .exists(file, line)
    }
    
    func matching(_ text: String, _ file: StaticString = #filePath, _ line: UInt = #line) -> TestStep<AnnotatedElement> {
        self.map {
            let element = $0.query[text]
            return AnnotatedElement(queryType: .matching(text), element: element)
        }
        .exists(file, line)
    }
    
    func onlyElement(_ file: StaticString = #filePath, _ line: UInt = #line) -> TestStep<AnnotatedElement> {
        self.flatMap { query in
            let queryCount = query.query.count
            guard queryCount == 1 else {
                return .never(TestStepError(.unexpectedNumberOfElementsMatching(query: "Not implemented", expected: 1, got: queryCount), file: file, line: line))
            }
            return .always(AnnotatedElement(queryType: .onlyElement(query.type), element: query.query.firstMatch))
        }
    }
    
    func firstMatch() -> TestStep<AnnotatedElement> {
        map { query in
            AnnotatedElement(queryType: query.type, element: query.query.firstMatch)
        }
    }
}

public extension TestStep where Result == AnnotatedElement {
    
    func exists(_ file: StaticString = #filePath, _ line: UInt = #line) -> Self {
        flatMap { element in
            if element.element.exists {
                return .always(element)
            }
            return .never(TestStepError(.elementDoesNotExist(element: element), file: file, line: line))
        }
    }
    
    func wait(for timeout: TimeInterval = 2, _ file: StaticString = #filePath, _ line: UInt = #line) -> Self {
        flatMap { element in
            element.element.waitForExistence(timeout: timeout) ?
                .always(element) :
                .never(TestStepError(.timedOutWaitingFor(element: element), file: file, line: line))
        }
    }
    
    func tap(_ file: StaticString = #filePath, _ line: UInt = #line) -> Self {
        exists(file, line)
            .do {
                $0.element.tap()
                
            }
    }
    
    func type(_ text: String, _ file: StaticString = #filePath, _ line: UInt = #line) -> Self {
        exists(file, line)
            .zip(.init(run: { app in
                AnnotatedElement(queryType: .matchingPredicate("Boo bar"), element: app.keyboards.element)
            }).exists(file, line))
            .map(\.0)
            .do { $0.element.typeText(text) }
    }
}

public extension TestStep {
    
    func optional() -> TestStep<Result?> {
        TestStep<Result?> { app in
            try? self.run(app)
        }
    }
}

public extension TestStep {
    
    private static func locate(_ f: @escaping (XCUIApplication) -> XCUIElementQuery, matching text: String, _ file: StaticString = #filePath, _ line: UInt = #line) -> TestStep<AnnotatedElement> {
        TestStep<XCUIElementQuery>(run: f)
            .map(AnnotatedQuery.create(with: .matching(text)))
            .matching(text, file, line)
    }

    
    private static func predicateQuery(_ f: @escaping (XCUIApplication) -> XCUIElementQuery, predicate: NSPredicate) -> TestStep<AnnotatedQuery> {
        TestStep<XCUIElementQuery>(run: f)
            .map { AnnotatedQuery(type: .matchingPredicate(predicate.predicateFormat), query: $0.containing(predicate)) }
    }
    
    // MARK: Locating by label
    
    private static func labelQuery(in f: @escaping (XCUIApplication) -> XCUIElementQuery, containing text: String) -> TestStep<AnnotatedQuery> {
        predicateQuery(f, predicate: .containsIgnoringCase(property: "label", value: text))
    }
    
    private static func locateLabel(in f: @escaping (XCUIApplication) -> XCUIElementQuery, containing text: String, boundBy index: Int, _ file: StaticString = #filePath, _ line: UInt = #line) -> TestStep<AnnotatedElement> {
        labelQuery(in: f, containing: text).boundBy(index, file, line)
    }
    
    private static func locateFirstLabel(in f: @escaping (XCUIApplication) -> XCUIElementQuery, containing text: String) -> TestStep<AnnotatedElement> {
        labelQuery(in: f, containing: text).firstMatch()
    }
    
    private static func locateOnlyLabel(_ f: @escaping (XCUIApplication) -> XCUIElementQuery, containing text: String) -> TestStep<AnnotatedElement> {
        labelQuery(in: f, containing: text).onlyElement()
    }
    
    // MARK: Textfields
    
    private static func textfieldPlaceholder(containing text: String) -> TestStep<AnnotatedQuery> {
        predicateQuery(\.textFields, predicate: .containsIgnoringCase(property: "placeholderValue", value: text))
    }
    
    static func firstTextfield(matching text: String, file: StaticString = #filePath, line: UInt = #line) -> TestStep<AnnotatedElement> {
        // first check for placeholders and then labels
        textfieldPlaceholder(containing: text)
            .firstMatch()
            .orElse(locate(\.textFields, matching: text))
    }
    
    static func onlyTextfield(matching text: String) -> TestStep<AnnotatedElement> {
        textfieldPlaceholder(containing: text)
            .onlyElement()
            .orElse(locate(\.textFields, matching: text))
    }
    
    static func firstTextfield(containing text: String) -> TestStep<AnnotatedElement> {
        textfieldPlaceholder(containing: text)
            .firstMatch()
            .orElse(locateFirstLabel(in: \.textFields, containing: text))
    }
    
    static func textField(containing text: String) -> TestStep<AnnotatedQuery> {
        textfieldPlaceholder(containing: text)
            .orElse(labelQuery(in: \.textFields, containing: text))
    }
    
    static func textField(containing text: String, boundBy: Int) -> TestStep<AnnotatedElement> {
        textfieldPlaceholder(containing: text)
            .boundBy(boundBy)
            .orElse(
                locateLabel(in: \.textFields, containing: text, boundBy: boundBy)
            )
    }
    
    static func label(matching text: String) -> TestStep<AnnotatedElement> {
        locate(\.staticTexts, matching: text)
    }
    
    // MARK: - Buttons
    
    static func button(matching text: String, _ file: StaticString = #filePath, _ line: UInt = #line) -> TestStep<AnnotatedElement> {
        locate(\.buttons, matching: text, file, line)
    }
    
    static func buttons(containing text: String) -> TestStep<AnnotatedQuery> {
        labelQuery(in: \.buttons, containing: text)
    }
    
    // MARK: - Navigation
    
    static func navigationButton(matching text: String, _ file: StaticString = #filePath, _ line: UInt = #line) -> TestStep<AnnotatedElement> {
        locate(\.navigationBars.buttons, matching: text, file, line)
    }
    
    static func navigationBarTitle(matching title: String, _ file: StaticString = #filePath, _ line: UInt = #line) -> TestStep<AnnotatedElement> {
        locate(\.navigationBars.staticTexts, matching: title, file, line)
    }
    
    // MARK: - Cells
    
    static func cell(matching text: String, _ file: StaticString = #filePath, _ line: UInt = #line) -> TestStep<AnnotatedElement> {
        locate(\.cells, matching: text, file, line)
    }
    
    static func cell(containing text: String, _ file: StaticString = #filePath, _ line: UInt = #line) -> TestStep<AnnotatedQuery> {
        labelQuery(in: \.cells, containing: text)
    }
    
    #warning("Migrate to AnnotatedElement")
    static func element(matching elementType: XCUIElement.ElementType, with identifier: String) -> TestStep<XCUIElement> {
        .init { app in
            app.descendants(matching: elementType)
                .element(matching: elementType, identifier: identifier)
        }
    }
    
    func `do`(_ f: @escaping (Result) -> Void) -> Self {
        .init { app in
            let output = try self.run(app)
            f(output)
            return output
        }
    }
    
    func printResult() -> Self {
        self.do {
            print("\($0)")
        }
    }
}

public extension TestStep where Result == Bool {
   
    func assertTrue() -> Self {
        // TODO: This will need to change potentially to bubble up a warning/error
        self.do { result in
            XCTAssert(result)
        }
    }
}

extension NSPredicate {
    
    static func containsIgnoringCase(property: String, value: String) -> NSPredicate {
        NSPredicate(format: "\(property) CONTAINS[c] %@", value)
    }
}
