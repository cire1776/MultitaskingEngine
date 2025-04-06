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
    private var sources: SubscriptionMask = 0
    public private(set) var exhausted: SubscriptionMask = 0
    private var _available: SubscriptionMask = 0
   
    public init(sources: SubscriptionMask = .max) {
        self.sources = sources
        self.exhausted = 0
        self._available = 0
    }
    
    public var available: SubscriptionMask {
        get { _available & ~exhausted }
    }
    
    @inline(__always)
    public func areAllAvailable(_ mask: SubscriptionMask) -> Bool {
        (self.available & mask) == mask
    }
    
    @inline(__always)
    public func areAllExhausted() -> Bool {
        (self.exhausted & sources) == sources
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
    
    @inline(__always)
    public func reset() {
        self._available = 0
    }
}

final public class FlowEntity {
    public static func graphFlow(_ comprehension: Comprehension.Subscription, for entities: [(LintTable.Steppable?) -> LintTable.Steppable]) -> FlowEntity? {
        var current: FlowEntity? = nil
        for entity in entities.reversed() {
            current = FlowEntity(root: nil, next: current, table: entity(current?.table))
        }
        
        let root = current
        current = root?.next
        while current != nil {
            current?.root = root
            current = current?.next
        }
        
        return root
    }
    
    public private(set) var root: FlowEntity?
    public let next: FlowEntity?
    
    public let table: LintTable.Steppable

    public init(root: FlowEntity?, next: FlowEntity?, table: LintTable.Steppable) {
        self.root = root
        self.next = next
        self.table = table
    }
}

public enum Comprehension {
    public protocol Common: AnyObject, LintProvider {
        var executionContext: StreamExecutionContext { get }
        var table: LintTable.Steppable { get }
        
        var operationID: Int           { get }
        var operationName: String      { get }
        
        var mainLoopID: Int            { get }
        
        func instantiate(preinitialization_lint: Lint?, executionContext: StreamExecutionContext?) -> Instance
    }
    
    public protocol Standard: Common {  }
    
    public protocol Subscription: Common {
        var subscriptions: Subscriptions { get set }
    }
    
    final public class Instance: RunnableLintProvider {
        let blueprintName: String
        var executionContext: StreamExecutionContext
        public private(set) var table: LintTable.Steppable
        
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
    
    @inline(__always)
    public func subscriptionGuard(
        using inputSubscriptions: SubscriptionMask,
        emitting outputStreams: SubscriptionMask) -> OperationState {
        guard !subscriptions.areAllExhausted() else { return .nonLocalBreak(mainLoopID) }
        
        guard subscriptions.areAllAvailable(inputSubscriptions) else {
            subscriptions.unpublish(outputStreams)
            return .localBreak
        }
        
        return .running
    }
    
    @inline(__always)
    public func dispatch(on result: EntityResult, emitting outputStreams: SubscriptionMask) -> OperationState {
        switch result {
        case .notAvailable:
            subscriptions.unpublish(outputStreams)
         case .eof:
            subscriptions.exhaust(outputStreams)
        case .proceed:
            subscriptions.publish(outputStreams)
        case .unusualExecutionEvent:
            assert(executionContext.pendingEvent != nil)
            return .unusualExecutionEvent(executionContext.pendingEvent!)
        }
        
        return .running
    }
}
