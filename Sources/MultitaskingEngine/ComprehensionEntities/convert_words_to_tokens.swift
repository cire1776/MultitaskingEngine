//
//  convert_words_to_tokens.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 4/7/25.
//

final public class ConvertWordsToTokens: Comprehension.ExecutionEntity {
    private let executionContext: StreamExecutionContext
    private let inputStream: String
    private let outputStream: String

    public let subscriptions: SubscriptionMask
    public var publishes: SubscriptionMask

    public init(aliasMap: [String: String] = [:], executionContext: StreamExecutionContext, subscriptions: SubscriptionMask, publishes: SubscriptionMask) {
        self.inputStream = aliasMap["input"] ?? "input"
        self.outputStream = aliasMap["output"] ?? "output"
        self.executionContext = executionContext
        self.subscriptions = subscriptions
        self.publishes = publishes
    }

    func initialize() {}

   public func process() -> EntityResult {
        guard case let .success(word as String) = executionContext[inputStream] else {
            return .notAvailable
        }

        executionContext[outputStream] = .success(word)
        return .proceed
    }

    func finalize() {}
}
