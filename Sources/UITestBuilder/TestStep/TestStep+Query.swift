import XCTest

extension TestStep where Result == AnnotatedQuery {

    public func boundBy(_ index: Int, _ file: StaticString = #filePath, _ line: UInt = #line) -> TestStep<AnnotatedElement> {
        map {
            let element = $0.query.element(boundBy: index)
            return AnnotatedElement(queryType: .boundBy(index), element: element)
        }
    }

    public func onlyElement(_ file: StaticString = #filePath, _ line: UInt = #line) -> TestStep<AnnotatedElement> {
        flatMap { query in
            // In order to provide a timely, and useful error message we can't look at the `query.elemnt` as that'll trap if there is more than one.
            // This isn't for free, we pay a performance cost of running the query to get a stronger assertion.
            guard query.query.count == 1 else {
                return .fail(TestStepError(.noElementsMatchingQuery(query: query), file: file, line: line))
            }
            return .always(AnnotatedElement(queryType: .onlyElementOf(query.type), element: query.query.firstMatch))
        }
    }

    public func first() -> TestStep<AnnotatedElement> {
        map { query in
            AnnotatedElement(queryType: query.type, element: query.query.firstMatch)
        }
    }

    public func wait(for timeout: TimeInterval = Defaults.timeout, for minQueryCount: Int = 1, _ file: StaticString = #filePath, _ line: UInt = #line) -> Self {
        wait(
            for: timeout,
            predicate:  NSPredicate(format: "count >= \(minQueryCount)"),
            didFailError: { query in
                TestStepError(.timedOutWaitingForQuery(query: query), file: file, line: line)
            }
        )
    }

    public func wait(for timeout: TimeInterval = Defaults.timeout, for minQueryCount: Int = 1, predicate: NSPredicate, _ file: StaticString = #filePath, _ line: UInt = #line) -> Self {
        // Wait until the query matches the supplied minimum query count AND the supplied query
        wait(
            for: timeout,
            predicate: NSCompoundPredicate(andPredicateWithSubpredicates: [NSPredicate(format: "count >= \(minQueryCount)"), predicate]),
            didFailError: { query in
                TestStepError(.timedOutWaitingForQueryWithPredicate(query: query, predicate: predicate), file: file, line: line)
            }
        )
    }

    func wait(for timeout: TimeInterval = Defaults.timeout, predicate: NSPredicate, didFailError: @escaping (AnnotatedQuery) -> TestStepError) -> TestStep<AnnotatedQuery> {
        flatMap { query in
            let waiter = XCTWaiter()
            let result = waiter.wait(for: [XCTNSPredicateExpectation(predicate: predicate, object: query.query)], timeout: timeout)
            switch result {
            case .completed:
                return .always(query)
            default:
                return .fail(didFailError(query))
            }
        }
    }
}

/// Functions for transforming a TestStep of XCUIElementQuery into an "Annotated" type (Query or Element).
extension TestStep where Result == XCUIElementQuery {

    public func first() -> TestStep<AnnotatedElement> {
        map { AnnotatedElement(queryType: .first, element: $0.firstMatch) }
    }

    public func boundBy(_ index: Int) -> TestStep<AnnotatedElement> {
        map { AnnotatedElement(queryType: .boundBy(index), element: $0.element(boundBy: index)) }
    }

    public func matching(exactly text: String, _ file: StaticString = #filePath, _ line: UInt = #line) -> TestStep<AnnotatedElement> {
        map { AnnotatedElement(queryType: .matching(text), element: $0[text]) }
            .exists(file, line)
    }

    public func matching(predicate: NSPredicate) -> TestStep<AnnotatedQuery> {
        map { AnnotatedQuery(type: .matchingPredicate(predicate.predicateFormat), query: $0.matching(predicate)) }
    }

    public func matching(accessibility identifier: String) -> TestStep<AnnotatedQuery> {
        map { AnnotatedQuery(type: .matchingIdentifier(identifier), query: $0.matching(identifier: identifier)) }
    }

    public func containing(_ text: String) -> TestStep<AnnotatedQuery> {
        matching(predicate: .labelContains(value: text))
    }

    public func placeholder(containing text: String) -> TestStep<AnnotatedQuery> {
        matching(predicate: .placeholderContains(value: text))
    }
}

extension TestStep where Result == Bool {

    public func assert(_ file: StaticString = #filePath, _ line: UInt = #line) -> Self {
        self.flatMap { result in
            result ? .always(result) : .fail(TestStepError(.assertionFailed, file: file, line: line))
        }
    }
}
