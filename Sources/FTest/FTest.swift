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
    
    // Not sure might delete later
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
            return "Keyboard wasn't displayed! Make sure it's disabled under \"Simulator > IO > Keyboard > Connect Hardware Keyboard\""
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
                return .never(TestStepError(.unexpectedNumberOfElementsMatching(query: query, expected: 1, got: queryCount), file: file, line: line))
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
    
    func exists(_ file: StaticString = #filePath, _ line: UInt = #line) -> TestStep<Void> {
        let result: Self = exists(file, line)
        return result.map { _ in }
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
    
    func tap(_ file: StaticString = #filePath, _ line: UInt = #line) -> TestStep<Void> {
        let result: Self = tap(file, line)
        return result.map { _ in }
    }
    
    func type(_ text: String, _ file: StaticString = #filePath, _ line: UInt = #line) -> Self {
        exists(file, line)
            .zip(.init(run: { app in
                AnnotatedElement(queryType: .keyboard, element: app.keyboards.element)
            }).exists(file, line))
            .map(\.0)
            .do { $0.element.typeText(text) }
    }
    
    func type(_ text: String, _ file: StaticString = #filePath, _ line: UInt = #line) -> TestStep<Void> {
        let result: Self = type(text, file, line)
        return result.map { _ in }
    }
}

public extension TestStep {
    
    func optional() -> TestStep<Result?> {
        TestStep<Result?> { app in
            try? self.run(app)
        }
    }
}

private func locate(_ f: @escaping (XCUIApplication) -> XCUIElementQuery, matching text: String, _ file: StaticString = #filePath, _ line: UInt = #line) -> TestStep<AnnotatedElement> {
    TestStep<XCUIElementQuery>(run: f)
        .map(AnnotatedQuery.create(with: .matching(text)))
        .matching(text, file, line)
}


private func predicateQuery(_ f: @escaping (XCUIApplication) -> XCUIElementQuery, predicate: NSPredicate) -> TestStep<AnnotatedQuery> {
    TestStep<XCUIElementQuery>(run: f)
        .map { AnnotatedQuery(type: .matchingPredicate(predicate.predicateFormat), query: $0.containing(predicate)) }
}

// MARK: Locating by label

private func labelQuery(in f: @escaping (XCUIApplication) -> XCUIElementQuery, containing text: String) -> TestStep<AnnotatedQuery> {
    predicateQuery(f, predicate: .containsIgnoringCase(property: "label", value: text))
}

private func locateLabel(in f: @escaping (XCUIApplication) -> XCUIElementQuery, containing text: String, boundBy index: Int, _ file: StaticString = #filePath, _ line: UInt = #line) -> TestStep<AnnotatedElement> {
    labelQuery(in: f, containing: text).boundBy(index, file, line)
}

private func locateFirstLabel(in f: @escaping (XCUIApplication) -> XCUIElementQuery, containing text: String) -> TestStep<AnnotatedElement> {
    labelQuery(in: f, containing: text).firstMatch()
}

private func locateOnlyLabel(_ f: @escaping (XCUIApplication) -> XCUIElementQuery, containing text: String) -> TestStep<AnnotatedElement> {
    labelQuery(in: f, containing: text).onlyElement()
}

// MARK: - Textfields

private func textfieldPlaceholder(containing text: String) -> TestStep<AnnotatedQuery> {
    predicateQuery(\.textFields, predicate: .containsIgnoringCase(property: "placeholderValue", value: text))
}

public func textFields(containing text: String) -> TestStep<AnnotatedQuery> {
    textfieldPlaceholder(containing: text).orElse(labelQuery(in: \.textFields, containing: text))
}

// MARK: - Static Texts

public func staticTexts(matching text: String) -> TestStep<AnnotatedElement> {
    locate(\.staticTexts, matching: text)
}

// MARK: - Buttons

public func button(matching text: String, _ file: StaticString = #filePath, _ line: UInt = #line) -> TestStep<AnnotatedElement> {
    locate(\.buttons, matching: text, file, line)
}

public func buttons(containing text: String) -> TestStep<AnnotatedQuery> {
    labelQuery(in: \.buttons, containing: text)
}

// MARK: - Navigation

public func navigationButton(matching text: String, _ file: StaticString = #filePath, _ line: UInt = #line) -> TestStep<AnnotatedElement> {
    locate(\.navigationBars.buttons, matching: text, file, line)
}

public func navigationBarTitle(matching title: String, _ file: StaticString = #filePath, _ line: UInt = #line) -> TestStep<AnnotatedElement> {
    locate(\.navigationBars.staticTexts, matching: title, file, line)
}

// MARK: - Cells

public func cell(matching text: String, _ file: StaticString = #filePath, _ line: UInt = #line) -> TestStep<AnnotatedElement> {
    locate(\.cells, matching: text, file, line)
}

public func cell(containing text: String, _ file: StaticString = #filePath, _ line: UInt = #line) -> TestStep<AnnotatedQuery> {
    labelQuery(in: \.cells, containing: text)
}

// MARK: - Keyboard

public let dismissKeyboard: TestStep<Void> = {
    TestStep<XCUIElementQuery>(run: \.keyboards)
        .map(\.buttons)
        .map(queryContainingPredicate(.labelContains(value: "return")))
        .map { _ in }
}()

func queryContainingPredicate(_ predicate: NSPredicate) -> (XCUIElementQuery) -> XCUIElementQuery {
    return { query in
        query.containing(predicate)
    }
}

#warning("Migrate to AnnotatedElement")
public func element(matching elementType: XCUIElement.ElementType, with identifier: String) -> TestStep<XCUIElement> {
    .init { app in
        app.descendants(matching: elementType)
            .element(matching: elementType, identifier: identifier)
    }
}


public extension TestStep {
    func `do`(_ f: @escaping (Result) -> Void) -> Self {
        .init { app in
            let output = try self.run(app)
            f(output)
            return output
        }
    }
    
    func printResult(prefix: String = "") -> Self {
        self.do {
            print("\(prefix)\($0)")
        }
    }
}

public extension TestStep where Result == Bool {
    
    func assertTrue(_ file: StaticString = #filePath, _ line: UInt = #line) -> Self {
        self.flatMap { result in
            result ?
                .always(result) :
                .never(TestStepError(.assertionFailed, file: file, line: line))
        }
    }
}

extension NSPredicate {
    
    static func containsIgnoringCase(property: String, value: String) -> NSPredicate {
        NSPredicate(format: "\(property) CONTAINS[c] %@", value)
    }
    
    static func labelContains(value: String) -> NSPredicate {
        containsIgnoringCase(property: "label", value: value)
    }
    
    static func placeholderContains(value: String) -> NSPredicate {
        containsIgnoringCase(property: "placeholder", value: value)
    }
}

@resultBuilder
public struct TestBuilder {
    
    public static func buildBlock(_ components: TestStep<Void>...) -> TestStep<Void> {
        TestStep { app in
            for comp in components {
                try comp.run(app)
            }
        }
       
    }
}

extension TestStep {
    
    public init(@TestBuilder steps: @escaping () -> TestStep<Result>) {
        self.init { app in
            try steps().run(app)
        }
    }
}

#warning("Just experimenting with different syntaxes")
extension String {
    
    /*
     "From >".buttons.firstMatch().wait().tap()
     fromAccount.buttons.firstMatch().wait().tap()
     */
    
    var buttons: TestStep<AnnotatedQuery> {
        FTest.buttons(containing: self)
    }
}
