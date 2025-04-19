//
//  comprehensions.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 3/31/25.
//

import Foundation

public enum EntityResult: Equatable {
    case proceed
    case pump(SubscriptionMask)
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
    
    @inline(__always)
    public func visit(_ body: (_ index: Int, _ source: Bool, _ available: Bool, _ exhausted: Bool) -> Void) {
        var active = sources | exhausted | available
        
        var index = 0
        
        while active != 0 {
            if (active & 1) != 0 {
                let mask = UInt32(1) << index
                body(
                    index,
                    (sources & mask) != 0,
                    (self.available & mask) != 0,
                    (exhausted & mask) != 0
                )
            }
            
            active >>= 1
            index += 1
        }
    }
}

final public class FlowEntity {
    public static func graphFlow(_ comprehension: Comprehension.Subscription, for entities: [(LintTable.Steppable?) -> LintTable.Steppable]) -> FlowEntity? {
        var current: FlowEntity?
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

        var operationID: Int { get }
        var operationName: String { get }

        var mainLoopID: Int { get }
        var tickFlowID: Int { get }

        init(executionContext: StreamExecutionContext?)

        func instantiate(preinitialization_lint: Lint?, executionContext: StreamExecutionContext?) -> Instance
    }

    public protocol Standard: Common {  }

    public protocol Subscription: Common {
        var context: SubscriptionStreamExecutionContext { get }

        var pumpers: [Int] { get set }

        @inline(__always)
        func modifyTickLints(_ lints: inout LintArray)

        @inline(__always)
        func produceTickFlow(flows: [(LintRunner) -> LintTable.Steppable]) -> LintTable.Steppable

        @inline(__always)
        func produceMainLoop(tickFlowEntityBlocks: [(LintRunner) -> LintTable.Steppable]) -> LintTable.Steppable
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
        var publishes: SubscriptionMask { get }
    }

    public protocol ExecutionEntity {
        func process() -> EntityResult
    }

    public protocol DataSourceEntity {
        func next() -> EntityResult
    }

    public protocol FilterEntity {
        func include() -> EntityResult
    }

    public protocol DrainableEntity: ExecutionEntity {
        func drain() -> EntityResult
    }
}

public extension Comprehension.Standard {
    var operationName: String {
        "Comprehension_\(String(format: "%X", operationID))"
    }
}

public extension Comprehension.Subscription {
    var operationName: String {
        "Comprehension_S_\(String(format: "%X", operationID))"
    }

    @inline(__always)
    func subscriptionGuard(
        using inputSubscriptions: SubscriptionMask,
        emitting outputStreams: SubscriptionMask) -> OperationState {
            guard !context.subscriptions.areAllExhausted() else {
            executionContext.executionMode = .draining
            return .localBreak
        }

            guard context.subscriptions.areAllAvailable(inputSubscriptions) else {
                context.subscriptions.unpublish(outputStreams)
            return .localBreak
        }

        return .running
    }

    @inline(__always)
    func drainableSubscriptionGuard(
        using inputSubscriptions: SubscriptionMask,
        emitting outputStreams: SubscriptionMask) -> OperationState {
        guard !context.subscriptions.areAllExhausted() else {
            executionContext.executionMode = .draining
            return .running
        }

        guard context.subscriptions.areAllAvailable(inputSubscriptions) else {
            context.subscriptions.unpublish(outputStreams)
            return .localBreak
        }

        return .running
    }

    @inline(__always)
    func dispatch(on result: EntityResult,
                  using inputStreams: SubscriptionMask=0,
                  emitting outputStreams: SubscriptionMask=0,
                  on runner: LintRunner?=nil) -> OperationState {
        switch result {
        case .notAvailable where (context.subscriptions.exhausted & inputStreams) != 0:
            fallthrough
        case .eof:
            context.subscriptions.exhaust(outputStreams)
        case .notAvailable:
            context.subscriptions.unpublish(outputStreams)
        case .proceed:
            context.subscriptions.publish(outputStreams)
        case .pump:
            context.subscriptions.publish(outputStreams)
            guard let runner = runner else {
                fatalError("runner must be provided for pumper.")
            }
            assert(runner.previousTableNode?.counter != nil, "runner must be at pumpable level.")
            pumpers.append(runner.previousTableNode!.counter)
        case .unusualExecutionEvent:
            assert(executionContext.pendingEvent != nil)
            return .unusualExecutionEvent(executionContext.pendingEvent!)
        }

        return .running
    }

    @inline(__always)
    func modifyTickLints(_ lints: inout LintArray) {  }

    @inline(__always)
    func produceTickFlow(flows: [(LintRunner) -> LintTable.Steppable]) -> LintTable.Steppable {
        var lints: LintArray = flows.map { block in
            { $0.pushSuboperation(table: block($0)); return .skipYield }
        }

        modifyTickLints(&lints)

        lints.append({ [self] in
            if let pumper = self.pumpers.popLast() {
                $0.lintCounter = pumper - 1
                self.executionContext.executionMode = .standard
                return .running
            }
            return executionContext.isDraining ? .nonLocalBreak(mainLoopID) : .completed
        })

        return LintTable.Sequential(lints: lints, identifier: self.tickFlowID)
    }

    @inline(__always)
    func produceMainLoop(tickFlowEntityBlocks: [(LintRunner) -> LintTable.Steppable]) -> LintTable.Steppable {
        return LintTable.Loop(lints: [
            { [/*unowned*/ self] _ in context.subscriptions.reset(); return .running },
            { [/*unowned*/ self] in
                $0.pushSuboperation(table: produceTickFlow(flows: tickFlowEntityBlocks)); return .skipYield
            },
            { [/*unowned*/ self] _ in executionContext.endTick(); return .completed } // continue to loop
        ], identifier: mainLoopID)
    }

    func instantiate(preinitialization_lint: Lint?, executionContext: StreamExecutionContext?) -> Comprehension.Instance {
        return Comprehension.Instance(blueprint: self, preinitializationLint: preinitialization_lint, executionContext: executionContext)
    }
}
