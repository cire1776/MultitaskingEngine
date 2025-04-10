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
    
    public var subscriptions: SubscriptionMask = .max
    
    public init(aliasMap: [String: String] = [:], executionContext: StreamExecutionContext) {
        self.executionContext = executionContext
    }
    
    func process(publishes: SubscriptionMask=0) -> EntityResult {
        print(executionContext.dumpStreams())
        return .proceed
    }
}
