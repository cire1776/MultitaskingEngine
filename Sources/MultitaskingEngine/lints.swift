//
//  lints.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 4/1/25.
//

public typealias Lint = (LintRunner) -> OperationState
public typealias LintArray = [Lint]

public struct LintTable {
    public enum Category: Int {
        case sequential
        case concurrent
        case loop
        case guarded
        // add other types as needed
    }
    
    public class Node {
        let table: LintTable
        var counter: Int
        let previous: LintTable.Node?

        init(table: LintTable, counter: Int, previous: LintTable.Node?) {
            self.table = table
            self.counter = counter
            self.previous = previous
        }
    }
   
    init(lints: LintArray, category: Category = .sequential, identifier: Int=0) {
        self.lints = lints
        self.category = category
        self.identifier = identifier
    }
    
    public var lints: LintArray
    public var category: Category
    public var identifier: Int
}

public protocol LintProvider {
    var table: LintTable { get }
    var operationName: String { get }
}

public protocol LintRunner: AnyObject {
    var table: LintTable { get set }
    var lintCounter: Int { get set }
    
    var previousTableNode: LintTable.Node? { get set }

    func pushSuboperation(lints: LintArray, category: LintTable.Category, identifier: Int)
    func popSuboperation()
}

extension LintRunner {
    @inline(__always)
    public func pushSuboperation(lints: LintArray, category: LintTable.Category = .sequential, identifier: Int=0) {
        let table = LintTable(lints: lints, category: category, identifier: identifier)
        let node = LintTable.Node(table: self.table, counter: self.lintCounter, previous: previousTableNode)
        self.table = table
        previousTableNode = node
        self.lintCounter = -1
    }

    @inline(__always)
    public func popSuboperation() {
        guard let previous = previousTableNode else { return }
        self.table = previous.table
        self.lintCounter = previous.counter
        self.previousTableNode = previous.previous
    }
}

public protocol RunnableLintProvider: LintProvider {  }

public class ManualLintRunner: LintRunner {
    public var table: LintTable
    public var lintCounter: Int = 0
    
    public var previousTableNode: LintTable.Node? = nil
    
    public init(provider: RunnableLintProvider) {
        self.table = provider.table
    }
    
    public func execute() -> OperationState {
        execution: while lintCounter < table.lints.count {
            let result = table.lints[lintCounter](self)
            switch result {
            case .running:
                // Continue to next lint.
                break
            case .completed:
                break execution
            case .suspended, .unusualExecutionEvent:
                // Exit early if a lint signals suspension or an error.
                return result
            default:
                break
            }
            lintCounter += 1
        }
        return .completed
    }
}
