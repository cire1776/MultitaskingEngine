//
//  lints.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 4/1/25.
//

public typealias Lint = (LintRunner) async -> OperationState
public typealias LintArray = [Lint]

// MARK: - LintTable and Concrete Types
public enum LintTable {
    public enum Category: Int {
        case sequential
        case concurrent
        case loop
        case guarded
        // add other types as needed
    }

    public protocol Steppable {
        var identifier: Int { get set }
        
        var lintCount: Int  { get }

        // Execute the next lint and return an OperationState.
        func executionStep(runner: LintRunner) async -> OperationState

        mutating func prepend(_ lint: @escaping Lint)
    }

    public class Node {
        let table: LintTable.Steppable
        var counter: Int
        let previous: LintTable.Node?

        init(table: LintTable.Steppable, counter: Int, previous: LintTable.Node?) {
            self.table = table
            self.counter = counter
            self.previous = previous
        }
    }
}

extension LintTable {
    /// A sequential lint table simply iterates over its lint chain once.
    public struct Sequential: Steppable {
        public var lints: LintArray
        public var identifier: Int
        
        public var lintCount: Int { lints.count }

        public init(lints: LintArray, identifier: Int = 0) {
            self.lints = lints
            self.identifier = identifier
        }

        public mutating func prepend(_ lint: @escaping Lint) {
            lints.insert(lint, at: 0)
        }

        @inline(__always)
        public func executionStep(runner: LintRunner) async -> OperationState {
            guard runner.lintCounter < self.lints.count else { return .completed }

            return await lints[runner.lintCounter](runner)
        }
    }

    /// A loop lint table resets its counter once a lint signals .completed.
    public struct Loop: Steppable {
        public var lints: LintArray
        public var identifier: Int
        
        public var lintCount: Int { lints.count }

        public init(lints: LintArray, identifier: Int = 0) {
            self.lints = lints
            self.identifier = identifier
        }

        public mutating func prepend(_ lint: @escaping Lint) {
            lints.insert(lint, at: 0)
        }

        public func executionStep(runner: LintRunner) async -> OperationState {
            if runner.lintCounter >= self.lints.count {
                runner.lintCounter = 0
            }
            let result = await lints[runner.lintCounter](runner)
            if result == .completed {
                runner.lintCounter = -1
                return .running
            }
            return result
        }
    }

    public class Prefaced: Steppable {
        private var preface: LintTable.Sequential
        private var main: LintTable.Steppable
        
        public var lintCount: Int { isPrefaceRunning ? preface.lintCount : main.lintCount }

        private var isPrefaceRunning = true
        private var aborted: Bool = false

        public var identifier: Int

        public init(preface: LintTable.Sequential, main: LintTable.Steppable, identifier: Int=0) {
            self.preface = preface
            self.main = main

            self.identifier = identifier
        }

        public func prepend(_ lint: @escaping Lint) {
            fatalError("Not Implemented")
        }

        public func executionStep(runner: LintRunner) async -> OperationState {
            if aborted { return .completed }

            if isPrefaceRunning {
                let result = await preface.executionStep(runner: runner)
                if result == .running { return .running }
                self.isPrefaceRunning = false
                if result != .completed {
                    aborted = true
                    return result
                }
                runner.lintCounter = -1
                return .running
            } else {
                return await main.executionStep(runner: runner)
            }
        }
    }
}

public protocol LintProvider: AnyObject {
    var table: LintTable.Steppable { get }
    var operationName: String { get }
}

public protocol LintRunner: AnyObject {
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

public class ManualLintRunner: LintRunner {
    public var table: LintTable.Steppable
    public var lintCounter: Int = 0

    public var reference: AnyObject

    public var previousTableNode: LintTable.Node?

    public init(provider: RunnableLintProvider) {
        self.table = provider.table
        self.reference = provider // held to prevent disposal
    }

    public func executeAll() async -> OperationState {
        var result: OperationState
        repeat { result = await execute() } while result == .running
        return result
    }

    public func execute() async -> OperationState {
        let result = await table.executionStep(runner: self)

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
            return await execute()
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
            // Exit early if a lint signals suspension or an error.
            return result
            default:
            fatalError("unexpected case: \(result)")
        }
        lintCounter += 1
        return .running
     }
}
