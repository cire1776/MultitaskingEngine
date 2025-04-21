//
//  lint_table.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 4/20/25.
//


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
        
        mutating func prepend(_ specifier: LintSpecifier)

        #if DEBUG
        var allMetadata: [LintMetadata] { get }

        @inline(__always)
        func didStepRun(runner: LintRunner) -> Bool
        
        @inline(__always)
        func metadata(runner: LintRunner) -> LintMetadata
        #endif
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

        #if DEBUG
        public var allMetadata: [LintMetadata]
        
        public func didStepRun(runner: any LintRunner) -> Bool {
            return runner.lintCounter < self.lints.count
        }
        #endif

        public init(lints: LintArray, identifier: Int = 0) {
            self.lints = lints
            self.identifier = identifier
            self.allMetadata = Array(repeating: LintSpecifier.NULL.metadata, count: lints.count)
        }

        public init(specifiers: [LintSpecifier], identifier: Int = 0) {
            self.init(lints: specifiers.map(\.lint), identifier: identifier)

            #if DEBUG
            assert(allMetadata.count == lints.count)
            self.allMetadata = specifiers.map(\.metadata)
            #endif
        }

        public mutating func prepend(_ specifier: LintSpecifier) {
            lints.insert(specifier.lint, at: 0)
            allMetadata.insert(specifier.metadata,at: 0)
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
            self.allMetadata = Array(repeating: LintSpecifier.NULL.metadata, count: lints.count)
        }
        
        public init(specifiers: [LintSpecifier], identifier: Int = 0) {
            self.init(lints: specifiers.map(\.lint), identifier: identifier)

            #if DEBUG
            self.allMetadata = specifiers.map(\.metadata)
            assert(allMetadata.count == specifiers.count)
            #endif
        }

       public mutating func prepend(_ specifier: LintSpecifier) {
           lints.insert(specifier.lint, at: 0)
           allMetadata.insert(specifier.metadata, at: 0)
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
        
        #if DEBUG
        public var allMetadata: [LintMetadata]
        
        
        public func didStepRun(runner: any LintRunner) -> Bool {
            // Loop always runs again unless externally terminated
            return true
        }
        #endif
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
            
            #if DEBUG
            self.allMetadata = main.allMetadata
            assert(allMetadata.count == main.lintCount)
            #endif
        }

       public func prepend(_ specifier: LintSpecifier) {
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
        
        #if DEBUG
        // not used
        public let allMetadata: [LintMetadata]
        
        public func metadata(runner: any LintRunner) -> LintMetadata {
            if isPrefaceRunning {
                return preface.metadata(runner: runner)
            } else {
                return main.metadata(runner: runner)
            }
        }
        
        public func didStepRun(runner: any LintRunner) -> Bool {
            if isPrefaceRunning {
                return runner.lintCounter < preface.lintCount
            } else {
                return main.didStepRun(runner: runner)
            }
        }
        #endif
    }
}

extension LintTable.Steppable {
    #if DEBUG
    @inline(__always)
    public func metadata(runner: LintRunner) -> LintMetadata {
        return runner.lintCounter < allMetadata.count ? allMetadata[runner.lintCounter] : .NULL
    }
    #endif
}

public protocol LintProvider: AnyObject {
    var table: LintTable.Steppable { get }
    var operationName: String { get }
}

