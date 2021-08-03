import XCTest

public extension TestStep where Result == AnnotatedQuery {
    
    func boundBy(_ index: Int, _ file: StaticString = #filePath, _ line: UInt = #line) -> TestStep<AnnotatedElement> {
        map {
            let element = $0.query.element(boundBy: index)
            return AnnotatedElement(queryType: .boundBy(index), element: element)
        }
    }
    
    func matching(exactly text: String, _ file: StaticString = #filePath, _ line: UInt = #line) -> TestStep<AnnotatedElement> {
        map {
            let element = $0.query[text]
            return AnnotatedElement(queryType: .matching(text), element: element)
        }
        .exists(file, line)
    }
        
    func matching(accessibility identifier: String) -> TestStep<AnnotatedQuery> {
        map {
            AnnotatedQuery(
                type: .matchingIdentifier(identifier),
                query: $0.query.matching(identifier: identifier)
            )
        }
    }
    
    func onlyElement(_ file: StaticString = #filePath, _ line: UInt = #line) -> TestStep<AnnotatedElement> {
        flatMap { query in
            // In order to provide a timely, and useful error message we can't look at the `query.elemnt` as that'll trap if there is more than one.
            // This isn't for free, we pay a performance cost of running the query to get a stronger assertion.
            guard query.query.count == 1 else {
                return .never(TestStepError(.noElementsMatchingQuery(query: query), file: file, line: line))
            }
            return .always(AnnotatedElement(queryType: .onlyElement(query.type), element: query.query.firstMatch))
        }
    }
    
    func first() -> TestStep<AnnotatedElement> {
        map { query in
            AnnotatedElement(queryType: query.type, element: query.query.firstMatch)
        }
    }
    
    func wait(timeout: TimeInterval = Defaults.timeout, for minQueryCount: Int = 1, _ file: StaticString = #filePath, _ line: UInt = #line) -> Self {
        flatMap { query in
            // Wait until the query matches the supplied minimum query count.
            let predicate = NSPredicate(format: "count >= \(minQueryCount)")
            let waiter = XCTWaiter()
            let result = waiter.wait(for: [XCTNSPredicateExpectation(predicate: predicate, object: query.query)], timeout: timeout)
            switch result {
            case .completed:
                return .always(query)
            case .timedOut, .incorrectOrder, .interrupted, .invertedFulfillment:
                return .never(TestStepError(.timedOutWaitingForQuery(query: query), file: file, line: line))
            @unknown default:
                return .never(TestStepError(.timedOutWaitingForQuery(query: query), file: file, line: line))
            }
        }
    }
}

public extension TestStep where Result == XCUIElementQuery {

    // TODO: matching exactly... that sucks for the caller.
    func matching(exactly text: String, _ file: StaticString = #filePath, _ line: UInt = #line) -> TestStep<AnnotatedElement> {
        map { AnnotatedElement(queryType: .matching(text), element: $0[text]) }
            .exists(file, line)
    }

    func matching(predicate: NSPredicate) -> TestStep<AnnotatedQuery> {
        map { AnnotatedQuery(type: .matchingPredicate(predicate.predicateFormat), query: $0.containing(predicate)) }
    }

    func containing(_ text: String) -> TestStep<AnnotatedQuery> {
        matching(predicate: .labelContains(value: text))
    }

    func placeholder(containing text: String) -> TestStep<AnnotatedQuery> {
        matching(predicate: .placeholderContains(value: text))
    }
}

public extension TestStep where Result == Bool {
    
    func assert(_ file: StaticString = #filePath, _ line: UInt = #line) -> Self {
        self.flatMap { result in
            result ?
                .always(result) :
                .never(TestStepError(.assertionFailed, file: file, line: line))
        }
    }
}
