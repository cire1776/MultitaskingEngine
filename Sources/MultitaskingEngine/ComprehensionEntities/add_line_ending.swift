//
//  add_line_ending.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 3/16/25.
//

public class AddLineEnding: Comprehension.Entity {
    let inputStream: String
    public var executionContext: StreamExecutionContext
    
    public init(aliasMap: [String: String], executionContext: StreamExecutionContext) {
        self.executionContext = executionContext
        self.inputStream = aliasMap["input"] ?? "input"
    }
   
    public var subscriptions: SubscriptionMask = .max

    func process(publishes: SubscriptionMask=0) -> EntityResult {
        guard let line = try? executionContext[inputStream].get() as? String else {
            return .notAvailable
        }

        if !line.hasSuffix("\n") {
             executionContext[inputStream] = .success(line + "\n")
        }

        return .proceed
    }
}
