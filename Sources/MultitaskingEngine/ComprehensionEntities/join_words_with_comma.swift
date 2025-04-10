//
//  join_words_with_comma.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 4/6/25.
//

final public class JoinWordsWithComma: Comprehension.Entity {
    private let executionContext: StreamExecutionContext
    private let inputStream: String
    private let outputStream: String

    public var subscriptions: SubscriptionMask = 0

    private var buffer: [String] = []

    public init(aliasMap: [String: String] = [:], executionContext: StreamExecutionContext) {
        self.inputStream = aliasMap["input"] ?? "input"
        self.outputStream = aliasMap["output"] ?? "output"
        self.executionContext = executionContext
    }

    func process() -> EntityResult {
        guard case let .success(word as String) = executionContext[inputStream] else {
            return .notAvailable
        }

        buffer.append(word)
        return .proceed  // or .pump if needed
    }

    func finalize() {
        let line = buffer.joined(separator: ",")
        executionContext[outputStream] = .success(line)
    }
}
