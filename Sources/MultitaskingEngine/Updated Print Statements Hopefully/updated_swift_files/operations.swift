import Foundation

// MARK: - OperationState Enum
public enum OperationState: Equatable {
    case initialization
    case firstRun
    case running
    case suspended  // yield
    case waitingForReturn   // ;
    case completed          // .
    case warning  (String)  // ;
    case exception(String)  // may return depending upon the exception handler
    case abort    (String)  // !
}

enum ExecutionFlags {
    static let yield: UInt64  = 1 << 0  // 0001 (Bit 0)
    static let stop: UInt64   = 1 << 1  // 0010 (Bit 1)
    static let abort: UInt64  = 1 << 2  // 0100 (Bit 2)
}

// MARK: - OperationExecutable Protocol
protocol OperationExecutable: AnyObject, Sendable {
    var operationName: String { get }
    var executionFlags: UInt64 { get set }  // ✅ Flags for execution control
    var state: OperationState { get set }
    var startTime: ContinuousClock.Instant { get set }
    var lastProcessed: UInt { get set }
    func execute() -> OperationState
}

class BaseOperationExecutable: OperationExecutable, @unchecked Sendable {
    let operationName: String
    var executionFlags: UInt64 = 0
    var state: OperationState = .initialization
    var startTime: ContinuousClock.Instant = ContinuousClock.now
    var lastProcessed: UInt = 0
    
    init(operationName: String) {
        self.operationName = operationName
    }

    func execute() -> OperationState {
        fatalError("Subclasses must override `execute`")
    }
}
