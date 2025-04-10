//
//  reroute.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 3/15/25.
//


final public class RerouteEntity: Comprehension.Entity {
    private var aliasMap: [String: String]

    let inputStream: String
    let outputStream: String
    var executionContext: StreamExecutionContext

    public var subscriptions: SubscriptionMask = .max
    
    public init(aliasMap: [String: String], executionContext: StreamExecutionContext) {
        self.aliasMap = aliasMap
        self.inputStream = aliasMap["input"] ?? "input"
        self.outputStream = aliasMap["output"] ?? "output"
        self.executionContext = executionContext
    }
    
    func initialize() {
        if !executionContext.containsKey(inputStream) {
            executionContext.triggerUnusualEvent(.exception("Missing input stream '\(inputStream)' in execution context."))
            return
        }
    }
    
    func process(publishes: SubscriptionMask=0) -> EntityResult {
        if case let .success(value) = executionContext[inputStream] {
            executionContext[outputStream] = .success(value)
            executionContext.remove(inputStream)
            return .proceed
        }
        return .notAvailable
    }
}
