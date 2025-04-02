import Foundation

// MARK: - OperationState Enum
public enum OperationState: Equatable {
    case initialization
    case firstRun
    case running
    case suspended          // yield
    case waitingForReturn   // ;
    case completed          // .
    case unusualExecutionEvent(UnusualExecutionEvent)
    // may  return depending upon the event
}

enum ExecutionFlags {
    static let yield: UInt64    = 1 << 0 // 0001 (Bit 0)
    static let severity: UInt64 = 1 << 1 // 0010 (Bit 1)
    static let stop: UInt64     = 1 << 2 // 0100 (Bit 2)
    static let abort: UInt64    = 1 << 3 // 1000 (Bit 3)
}

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

// MARK: - OperationExecutable Protocol
protocol OperationExecutable: AnyObject, Sendable {
    var operationName: String { get }
    var executionFlags: UInt64 { get set }  // Flags for execution control
    var state: OperationState { get set }
    var startTime: ContinuousClock.Instant { get set }
    var lastProcessed: UInt { get set }
    func execute() -> OperationState
}

public class Operation: @unchecked Sendable, OperationExecutable, LintRunner {
    public let operationName: String
    var executionFlags: UInt64 = 0
    var state: OperationState = .initialization
    var startTime: ContinuousClock.Instant = .now
    var lastProcessed: UInt = 0

    public var lints: LintArray = []
    public var lintCounter: Int = 0

    public var previousTable: LintTable.Node? = nil
    
    init(name: String?=nil, lints: LintArray) {
        self.operationName = name ?? "~unnamed~"
        self.lints = lints
    }

    func execute() -> OperationState {
        execution: while lintCounter < lints.count {
            if executionFlags & ExecutionFlags.yield != 0 {
                self.state = .running
                return .running
            }

            let result = lints[lintCounter](self)

            switch result {
            case .firstRun, .running:
                break
            case .completed:
                if previousTable != nil {
                    popSuboperation()
                    break
                }
                break execution
            case .suspended, .unusualExecutionEvent:
                self.state = result
                return result
            case .initialization, .waitingForReturn:
                break
            }

            lintCounter += 1
        }

        self.state = .completed
        return .completed
    }
}

public protocol LintProvider {
    var lints: [Lint] { get }
    var operationName: String { get }
}

public protocol LintRunner: AnyObject {
    var lints: [Lint] { get set }
    var lintCounter: Int { get set }
    
    var previousTable: LintTable.Node? { get set }

    func pushSuboperation(_ newLints: [Lint])
    func popSuboperation()
}

extension LintRunner {
    @inline(__always)
    public func pushSuboperation(_ newLints: [Lint]) {
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
    public var lints: [Lint]
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
