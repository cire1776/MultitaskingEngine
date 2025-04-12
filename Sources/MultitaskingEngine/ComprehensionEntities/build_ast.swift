//
//  Untitled.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 4/7/25.
//

final public class BuildAST: Comprehension.Entity {
    private let executionContext: StreamExecutionContext
    private let inputStream: String
    private let outputStream: String

    private var buffer: [Group] = []

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
        guard case let .success(token as Group) = executionContext[inputStream] else {
            return .notAvailable
        }

        buffer.append(token)
        return .proceed
    }

    func drain() -> EntityResult {
        return process()
    }
    
    func finalize() {
        executionContext[outputStream] = .success(buffer)
    }
}
