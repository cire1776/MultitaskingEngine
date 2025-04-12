//
//  print.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 3/21/25.

public class Print: Comprehension.ExecutionEntity {
    var executionContext: StreamExecutionContext
    let inputStream: String
    // no output
    
    public var subscriptions: SubscriptionMask
    public var publishes: SubscriptionMask
    
    public init(aliasMap: [String: String] = [:], executionContext: StreamExecutionContext, subscriptions: SubscriptionMask, publishes: SubscriptionMask) {
        self.executionContext = executionContext
        self.inputStream = aliasMap["input"] ?? "input"
        self.subscriptions = subscriptions
        self.publishes = publishes

    }
    
   public func process() -> EntityResult {
        if case let .success(output) = executionContext[inputStream] {
            print(output ?? "~nil~")
            return .proceed
        }
        return .notAvailable
    }
}
