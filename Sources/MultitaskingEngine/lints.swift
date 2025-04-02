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
        let lints: LintArray
        var counter: Int
        let previous: LintTable.Node?

        init(lints: LintArray, counter: Int, previous: LintTable.Node?) {
            self.lints = lints
            self.counter = counter
            self.previous = previous
        }
    }
    
    public let lints: LintArray
    public var category: Category
    public var identifier: Int
}

public protocol LintProvider {
    var lints: LintArray { get }
    var operationName: String { get }
}

public protocol LintRunner: AnyObject {
    var lints: LintArray { get set }
    var lintCounter: Int { get set }
    
    var previousTable: LintTable.Node? { get set }

    func pushSuboperation(_ newLints: LintArray, )
    func popSuboperation()
}

extension LintRunner {
    @inline(__always)
    public func pushSuboperation(_ newLints: LintArray) {
        let node = LintTable.Node(lints: self.lints, counter: self.lintCounter, previous: previousTable)
        previousTable = node
        self.lints = newLints
        self.lintCounter = -1
    }

    @inline(__always)
    public func popSuboperation() {
        guard let previous = previousTable else { return }
        self.lints = previous.lints
        self.lintCounter = previous.counter
        self.previousTable = previous.previous
    }
}

public protocol RunnableLintProvider: LintProvider {  }

public class ManualLintRunner: LintRunner {
    public var lints: LintArray
    public var lintCounter: Int = 0
    
    public var previousTable: LintTable.Node? = nil
    
    public init(provider: RunnableLintProvider) {
        self.lints = provider.lints
    }
    
    public func execute() -> OperationState {
        execution: while lintCounter < lints.count {
            let result = lints[lintCounter](self)
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
