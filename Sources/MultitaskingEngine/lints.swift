//
//  lints.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 4/1/25.
//

public typealias Lint = (LintRunner) -> OperationState
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
        
        // Execute the next lint and return an OperationState.
        func executionStep(runner: LintRunner) -> OperationState
        
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
        
        public init(lints: LintArray, identifier: Int = 0) {
            self.lints = lints
            self.identifier = identifier
        }
        
        public mutating func prepend(_ lint: @escaping Lint) {
            lints.insert(lint, at: 0)
        }
        
        @inline(__always)
        public func executionStep(runner: LintRunner) -> OperationState {
            guard runner.lintCounter < self.lints.count else { return .completed }
            
            return lints[runner.lintCounter](runner)
        }
    }
    
    /// A loop lint table resets its counter once a lint signals .completed.
    public struct Loop: Steppable {
        public var lints: LintArray
        public var identifier: Int
        
        public init(lints: LintArray, identifier: Int = 0) {
            self.lints = lints
            self.identifier = identifier
        }
                
        public mutating func prepend(_ lint: @escaping Lint) {
            lints.insert(lint, at: 0)
        }

        public func executionStep(runner: LintRunner) -> OperationState {
            if runner.lintCounter >= self.lints.count {
                runner.lintCounter = 0
            }
            return lints[runner.lintCounter](runner)
        }
    }
    
    public class Prefaced: Steppable {
        private var preface: LintTable.Sequential
        private var main: LintTable.Steppable
        
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
        
        public func executionStep(runner: LintRunner) -> OperationState {
            if aborted { return .completed }
            
            if (isPrefaceRunning) {
                let result = preface.executionStep(runner: runner)
                if result == .running { return .running }
                self.isPrefaceRunning = false
                if result != .completed {
                    aborted = true
                    return result
                }
                runner.lintCounter = -1
                return .running
            } else {
                return main.executionStep(runner: runner)
            }
        }
    }
}

public protocol LintProvider {
    var table: LintTable.Steppable { get }
    var operationName: String { get }
}

public protocol LintRunner: AnyObject {
    var table: LintTable.Steppable { get set }
    var lintCounter: Int { get set }
    
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
        var current = self.previousTableNode
        
        // Traverse until a node with a matching identifier is found.
        while let node = current, current?.table.identifier != identifier {
            current = node.previous
        }
        
        if let target = current {
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
    
    public var previousTableNode: LintTable.Node? = nil
    
    public init(provider: RunnableLintProvider) {
        self.table = provider.table
    }
   
    public func executeAll() -> OperationState {
        var result: OperationState
        repeat { result = execute() } while result == .running
        return result
    }
    
    public func execute() -> OperationState {
        let result = table.executionStep(runner: self)
        
        switch result {
        case .firstRun, .running:
            break
        case .completed:
            if previousTableNode != nil {
                popSuboperation()
                break
            }
            return .completed
        case .localBreak:
            if self.previousTableNode != nil {
                popSuboperation()
                return execute()
            }
            return .completed
        case .skipYield:
            return execute()
        case .nonLocalContinue(let identifier):
            if self.previousTableNode != nil {
                popSuboperation(identifier: identifier)
                return execute()
            }
            return .completed
        case .unusualExecutionEvent:
            // Exit early if a lint signals suspension or an error.
            return result
        default:
            fatalError("unexpected case: \(result)")
            break
        }
        lintCounter += 1
        return .running
     }
}
