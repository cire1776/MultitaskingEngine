//
//  skip_filter.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 3/13/25.
//

struct SkipFilter: Comprehension.Entity {
    private let valuesToSkip: Set<String>
    private let stream: String
    private let executionContext: StreamExecutionContext

    init(valuesToSkip: [String], stream: String, executionContext: StreamExecutionContext) {
        self.valuesToSkip = Set(valuesToSkip)
        self.stream = stream
        self.executionContext = executionContext
    }

    func initialize() {}

    func include() -> EntityResult {
        if !executionContext.containsKey(stream) { return .eof }

        let rawValue = try? executionContext[stream].get() as? String // ✅ Allows `nil`

        if let rawValue = rawValue, valuesToSkip.contains(rawValue) {
            return .notAvailable
        }

        return .proceed
    }

    func finalize() {}
}
