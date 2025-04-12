//
//  add_line_ending.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 3/16/25.
//

public class AddLineEnding: Comprehension.ExecutionEntity {
    let inputStream: String
    public var executionContext: StreamExecutionContext
    
    public init(aliasMap: [String: String], executionContext: StreamExecutionContext, subscriptions: SubscriptionMask, publishes: SubscriptionMask) {
        self.executionContext = executionContext
        self.inputStream = aliasMap["input"] ?? "input"
        self.subscriptions = subscriptions
        self.publishes = publishes
    }
   
    public var subscriptions: SubscriptionMask
    public var publishes: SubscriptionMask
    
    public func process() -> EntityResult {
        guard let line = try? executionContext[inputStream].get() as? String else {
            return .notAvailable
        }

        if !line.hasSuffix("\n") {
             executionContext[inputStream] = .success(line + "\n")
        }

        return .proceed
    }
}
