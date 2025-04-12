//
//  reroute.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 3/15/25.
//

final public class RerouteEntity: Comprehension.ExecutionEntity {
    private var aliasMap: [String: String]

    let inputStream: String
    let outputStream: String
    var executionContext: StreamExecutionContext

    public var subscriptions: SubscriptionMask
    public var publishes: SubscriptionMask

    public init(aliasMap: [String: String], executionContext: StreamExecutionContext, subscriptions: SubscriptionMask, publishes: SubscriptionMask) {
        self.aliasMap = aliasMap
        self.inputStream = aliasMap["input"] ?? "input"
        self.outputStream = aliasMap["output"] ?? "output"
        self.executionContext = executionContext
        self.subscriptions = subscriptions
        self.publishes = publishes
    }

    func initialize() {
        if !executionContext.containsKey(inputStream) {
            executionContext.triggerUnusualEvent(.exception("Missing input stream '\(inputStream)' in execution context."))
            return
        }
    }

   public func process() -> EntityResult {
        if case let .success(value) = executionContext[inputStream] {
            executionContext[outputStream] = .success(value)
            executionContext.remove(inputStream)
            return .proceed
        }
        return .notAvailable
    }
}
