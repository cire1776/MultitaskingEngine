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

    public var table: LintTable
    public var lintCounter: Int = 0

    public var previousTableNode: LintTable.Node? = nil
    
    init(name: String?=nil, provider: LintProvider) {
        self.table = provider.table
        self.operationName = name ?? "~unnamed~"
    }

    func execute() -> OperationState {
        execution: while lintCounter < table.lints.count {
            if executionFlags & ExecutionFlags.yield != 0 {
                self.state = .running
                return .running
            }

            let result = table.lints[lintCounter](self)

            switch result {
            case .firstRun, .running:
                break
            case .completed:
                if previousTableNode != nil {
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

