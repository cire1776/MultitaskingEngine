//
//  join_words_with_comma.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 4/6/25.
//

final public class JoinWordsWithComma: Comprehension.ExecutionEntity, Comprehension.DrainableEntity {
    private let executionContext: StreamExecutionContext
    private let inputStream: String
    private let outputStream: String

    public var subscriptions: SubscriptionMask
    public var publishes: SubscriptionMask
    
    private var buffer: [String] = []

    public init(aliasMap: [String: String] = [:], executionContext: StreamExecutionContext, subscriptions: SubscriptionMask, publishes: SubscriptionMask) {
        self.inputStream = aliasMap["input"] ?? "input"
        self.outputStream = aliasMap["output"] ?? "output"
        self.executionContext = executionContext
        self.subscriptions = subscriptions
        self.publishes = publishes
    }

   public func process() -> EntityResult {
        guard case let .success(word as String) = executionContext[inputStream] else {
            return .notAvailable
        }

        buffer.append(word)
        return .proceed  // or .pump if needed
    }

    public func drain() -> EntityResult {
        return .notAvailable
    }
    
    func finalize() {
        let line = buffer.joined(separator: ",")
        executionContext[outputStream] = .success(line)
    }
}
