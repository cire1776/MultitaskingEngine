//
//  identify_symbols.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 4/8/25.
//

import Foundation

final public class IdentifySymbols: Comprehension.Entity {
    private let executionContext: StreamExecutionContext
    private let inputStream: String
    private let outputStream: String
    
    public let subscriptions: SubscriptionMask = 0
    
    public init(aliasMap: [String: String] = [:], executionContext: StreamExecutionContext) {
        self.inputStream = aliasMap["input"] ?? "input"
        self.outputStream = aliasMap["output"] ?? "output"
        self.executionContext = executionContext
    }
    
    func process() -> EntityResult {
        print("---- Identifying Symbols ----")
        guard case .success(let nextChar as Character) = executionContext[inputStream],
              Group.classify(nextChar) == Group.Kind.symbol else {
            return .proceed
        }
        executionContext[inputStream] = .success(Group(kind: .symbol, value: String(nextChar)))
        print("emitting symbol: \(Group(kind: .symbol, value: String(nextChar)))")
        return .proceed
     }
}
