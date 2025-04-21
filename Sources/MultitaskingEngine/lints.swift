//
//  lints.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 4/1/25.
//
import Foundation

public typealias Lint = (LintRunner) async -> OperationState
public typealias LintArray = [Lint]

#if DEBUG
public struct LintMetadata {
    static nonisolated(unsafe) public let NULL = LintMetadata()
    public var role: String
    public var file: StaticString?
    public var line: UInt?
    public var column: UInt?
    public var description: StaticString?
    public var sourceSnippet: String?
    
    public var uLangEntityID: ULangEntityID
    
    public let isNull: Bool

    public var shortFilePath: String? {
        guard let fullPath = self.file else { return nil }

        let url = URL(fileURLWithPath: String(describing: fullPath))
        let filename = url.lastPathComponent
        let folder = url.deletingLastPathComponent().lastPathComponent

        return "\(folder)/\(filename)"
    }
   
    public init() {
        self.role = "NONE"
        self.uLangEntityID = ULangEntityID("null")
        self.isNull = true
    }

    public init(metadata: LintMetadata, uLangEntityID: ULangEntityID) {
        self.role = metadata.role
        self.uLangEntityID = uLangEntityID
        self.file = metadata.file
        self.line = metadata.line
        self.column = metadata.column
        self.description = metadata.description
        self.isNull = metadata.isNull
    }
    
    public init(role: String,
                uLangEntityID: ULangEntityID,
                file: StaticString?=nil,
                line: UInt?=nil,
                column: UInt?=nil,
                description: StaticString? = "nil") {
        self.role = role
        self.uLangEntityID = uLangEntityID
        self.file = file
        self.line = line
        self.column = column
        self.description = description
        self.isNull = false
        
        if let file = file,
           let line = line,
           let column = column {
            self.sourceSnippet = SourceSnippetExtractor.closureBody(from: file, at: line)
        }
    }
}
#endif

public struct LintSpecifier {
    static nonisolated(unsafe) public let NULL = LintSpecifier({ _ in .unusualExecutionEvent(.exception("Not expected to be executed.")) }, role: "NULL", uLangEntityID: "~NULL~")
    
    public let lint: Lint
    public let metadata: LintMetadata
   
    public init(
        _ lint: @escaping Lint,
        role: String = "unspecified lint",
        uLangEntityID: ULangEntityID,
        file: StaticString = #filePath,
        line: UInt = #line,
        column: UInt = #column
    ) {
        self.lint = lint
    
#if DEBUG
        self.metadata = LintMetadata(
            role: role,
            uLangEntityID: uLangEntityID,
            file: file,
            line: line,
            column: column,
        )
#else
        self.metadata = .NULL
#endif
    }
    
    public init(
        _ lint: @escaping Lint,
        role: String = "unspecified lint",
        file: StaticString = #filePath,
        line: UInt = #line,
        column: UInt = #column
    ) {
        self.lint = lint
    
#if DEBUG
        self.metadata = LintMetadata(
            role: role,
            uLangEntityID: .NULL,
            file: file,
            line: line,
            column: column,
        )
#else
        self.metadata = .NULL
#endif
    }
    
    public init(
        _ lint: @escaping Lint,
        metadata: LintMetadata,
        ulangeEntityID: ULangEntityID
    ) {
        self.lint = lint
    
        #if DEBUG
        self.metadata = LintMetadata(metadata: metadata, uLangEntityID: ulangeEntityID
        )
    #else
        self.metadata = .NULL
    #endif
    }
    
    public func withULangEntityID(_ uLangEntityID: ULangEntityID) -> LintSpecifier {
        guard self.metadata.isNull == false else {
            fatalError("NULL metadata not allowed for LintSpecifier")
        }
        let newMetadata: LintMetadata
        
        if self.metadata.uLangEntityID == uLangEntityID {
            newMetadata = LintMetadata(metadata: self.metadata, uLangEntityID: uLangEntityID)
        } else {
            newMetadata = self.metadata
        }
        
        let copy = LintSpecifier(
            lint,
            metadata: newMetadata,
            ulangeEntityID: uLangEntityID
        )
        return copy
    }
}

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
            assert(allMetadata.count == lints.count)
            assert(allMetadata.contains(where: {$0.role == nil}))
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

final public class ManualLintRunner: LintRunner, @unchecked Sendable {
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
        lintVisitor?(metadata, result)
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
