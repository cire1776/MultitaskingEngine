//
//  lint_runner.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 4/20/25.
//


public protocol LintRunner: AnyObject, Sendable {
    var table: LintTable.Steppable { get set }
    var lintCounter: Int { get set }

    var reference: AnyObject { get set }

    var previousTableNode: LintTable.Node? { get set }

    func pushSuboperation(table: LintTable.Steppable)
    func popSuboperation(identifier: Int)
}

extension LintRunner {
    @inline(__always)
    public func pushSuboperation(table newTable: LintTable.Steppable) {
        let node = LintTable.Node(table: self.table, counter: self.lintCounter, previous: previousTableNode)
        self.table = newTable
        previousTableNode = node
        self.lintCounter = 0
    }

    @inline(__always)
    public func popSuboperation(identifier: Int = 0) {
        var target = self.previousTableNode

        if identifier != 0 {
            var current = self.previousTableNode

            // Traverse until a node with a matching identifier is found.
            while identifier != 0,
                  let node = current,
                  current?.table.identifier != identifier {
                current = node.previous
            }
            target = current
        }

        if let target = target {
            self.table = target.table
            self.lintCounter = target.counter
            self.previousTableNode = target.previous
            if identifier != 0 {
                self.lintCounter += 1
            }
       }
    }
}

public protocol RunnableLintProvider: LintProvider {  }

open class BaseLintRunner: LintRunner, @unchecked Sendable {
    public var table: LintTable.Steppable
    public var lintCounter: Int = 0

    public var reference: AnyObject

    public var previousTableNode: LintTable.Node?

    #if DEBUG
    public var lintVisitor: ((LintMetadata, OperationState) -> Void)? = nil
    #endif
    
    public init(provider: RunnableLintProvider) {
        self.table = provider.table
        self.reference = provider // held to prevent disposal
    }

    open func handleSkipYield() async -> OperationState {
        return await execute()
    }

    public func executeAll() async -> OperationState {
        var result: OperationState
        repeat { result = await execute() } while result == .running
        return result
    }

    public func execute() async -> OperationState {
        #if DEBUG
        let metadata = table.metadata(runner: self)
        #endif

        let result = await table.executionStep(runner: self)

        #if DEBUG
        if table.didStepRun(runner: self) {
            lintVisitor?(metadata, result)
        }
        #endif
        
        switch result {
        case .firstRun, .running:
            break
        case .completed:
            if previousTableNode != nil {
                popSuboperation()
                self.lintCounter += 1
                return .running
            }
            return .completed
        case .localBreak:
            if self.previousTableNode != nil {
                popSuboperation()
                self.lintCounter += 1
                return await execute()
            }
            return .completed
        case .skipYield:
            return await handleSkipYield()
        case .nonLocalContinue(let identifier):
            if self.previousTableNode != nil {
                popSuboperation(identifier: identifier)
                return .running
            }
            return .completed
        case .nonLocalBreak(let identifier):
            if self.previousTableNode != nil {
                popSuboperation(identifier: identifier)
                popSuboperation()
                self.lintCounter += 1
                return await execute()
            }
            return .running
        case .unusualExecutionEvent:
            return result
        default:
            fatalError("unexpected case: \(result)")
        }

        lintCounter += 1
        return .running
    }
}

public final class ManualLintRunner: BaseLintRunner, @unchecked Sendable {
    // nothing to override
}
