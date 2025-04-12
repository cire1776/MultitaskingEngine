//
//  debug_stream.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 4/7/25.
//

final public class DebugStream: Comprehension.Entity {
    var executionContext: StreamExecutionContext
    // no input
    // no output
    
    public var subscriptions: SubscriptionMask
    public var publishes: SubscriptionMask
    
    public init(aliasMap: [String: String] = [:], executionContext: StreamExecutionContext, subscriptions: SubscriptionMask, publishes: SubscriptionMask) {
        self.executionContext = executionContext
        self.subscriptions = subscriptions
        self.publishes = publishes
    }
    
   public func process() -> EntityResult {
        print(executionContext.dumpStreams())
        return .proceed
    }
}
