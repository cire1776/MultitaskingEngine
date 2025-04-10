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

    public let subscriptions: SubscriptionMask = 0

    public init(aliasMap: [String: String] = [:], executionContext: StreamExecutionContext) {
        self.inputStream = aliasMap["input"] ?? "input"
        self.outputStream = aliasMap["output"] ?? "output"
        self.executionContext = executionContext
    }

    func initialize() {}

    func process(publishes: SubscriptionMask=0) -> EntityResult {
        guard case let .success(token as Group) = executionContext[inputStream] else {
            return .notAvailable
        }

        buffer.append(token)
        return .proceed
    }

    func drain(publishes: SubscriptionMask=0) -> EntityResult {
        return process(publishes: publishes)
    }
    
    func finalize() {
        executionContext[outputStream] = .success(buffer)
    }
}
