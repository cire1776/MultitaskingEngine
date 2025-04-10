//
//  convert_words_to_tokens.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 4/7/25.
//

final public class ConvertWordsToTokens: Comprehension.Entity {
    private let executionContext: StreamExecutionContext
    private let inputStream: String
    private let outputStream: String

    public let subscriptions: SubscriptionMask = 0

    public init(aliasMap: [String: String] = [:], executionContext: StreamExecutionContext) {
        self.inputStream = aliasMap["input"] ?? "input"
        self.outputStream = aliasMap["output"] ?? "output"
        self.executionContext = executionContext
    }

    func initialize() {}

    func process() -> EntityResult {
        guard case let .success(word as String) = executionContext[inputStream] else {
            return .notAvailable
        }

        executionContext[outputStream] = .success(word)
        return .proceed
    }

    func finalize() {}
}
