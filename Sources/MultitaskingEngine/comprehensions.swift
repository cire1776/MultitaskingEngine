//
//  comprehensions.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 3/31/25.
//

import Foundation

public enum EntityResult: Equatable {
    case proceed
    case notAvailable
    case eof
    case unusualExecutionEvent
}

final public class Subscriptions {
    public private(set) var exhausted: SubscriptionMask = 0
    private var _available: SubscriptionMask = 0
    
    public var available: SubscriptionMask {
        get { _available & ~exhausted }
    }
    
    @inline(__always)
    public func areAllAvailable(_ mask: SubscriptionMask) -> Bool {
        (self.available & mask) == mask
    }
    
    @inline(__always)
    public func areAllExhausted() -> Bool {
        self.exhausted == .max
    }

    @inline(__always)
    public func publish(_ mask: SubscriptionMask) {
        _available |= (mask & ~exhausted)
    }
    
    @inline(__always)
    public func unpublish(_ mask: SubscriptionMask) {
        _available &= ~mask
    }
    
    @inline(__always)
    public func exhaust(_ mask: SubscriptionMask) {
        exhausted |= mask
    }
}

public enum Comprehension {
    protocol Common: AnyObject, LintProvider {
        var executionContext: StreamExecutionContext { get }
        var table: LintTable.Steppable { get }
        
        var operationID: Int           { get }
        var operationName: String      { get }
        
        func instantiate(preinitialization_lint: Lint?, executionContext: StreamExecutionContext?) -> Instance
    }
    
    protocol Standard: Common {  }
    
    protocol Subscription: Common {  }
    
    final class Instance: RunnableLintProvider {
        let blueprintName: String
        var executionContext: StreamExecutionContext
        private(set) var table: LintTable.Steppable
        
        public var operationName: String {
            "\(blueprintName)__\(String(format: "%X", UUID().uuidString.hashValue))"
        }
        
        init(blueprint: Common, preinitializationLint: Lint?=nil, executionContext: StreamExecutionContext?=nil) {
            self.blueprintName = blueprint.operationName
            
            self.executionContext = executionContext ?? blueprint.executionContext

            self.table = blueprint.table
            
            if let preinitializationLint = preinitializationLint {
                self.table.prepend(preinitializationLint)
            }
        }
    }
    
    public protocol Entity {
        var subscriptions: SubscriptionMask { get }
    }
}

extension Comprehension.Standard {
    public var operationName: String {
        "Comprehension_\(String(format: "%X",operationID))"
    }
}


extension Comprehension.Subscription {
    public var operationName: String {
        "Comprehension_S_\(String(format: "%X",operationID))"
    }
}
