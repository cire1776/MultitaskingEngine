//
//  MultOperationingMocks.swift
//  ULang
//
//  Created by Eric Russell on 2/27/25.
//

@testable import MultitaskingEngine

final class MockOperation:OperationExecutable, @unchecked Sendable {
    var executionFlags: UInt64 = 0
    var state: MultitaskingEngine.OperationState = .suspended
    var startTime: ContinuousClock.Instant = .now
    var lastProcessed: UInt = 0
    let operationName: String
    private var states: [OperationState]
    private var currentStateIndex = 0

    init(operationName: String, states: [OperationState]) {
        self.operationName = operationName
        self.states = states
    }

    func execute() -> OperationState {
        if currentStateIndex < states.count {
            let state = states[currentStateIndex]
            currentStateIndex += 1

            if state == .completed {
                print("✅ \(operationName) has completed.")
                
                let currentValue = MultitaskingEngine.completedOperations.load(ordering: .relaxed)  // ✅ Read atomic value
                let newValue = currentValue + 1
                MultitaskingEngine.completedOperations.store(newValue, ordering: .relaxed)  // ✅ Store new atomic value  // ✅ Increment the global completed count
            }
            self.state = state
            return state
        }
        return .completed
    }
}

final actor MockExceptionHandler: ExceptionHandler, @unchecked Sendable {
    public var receivedExceptions: [(OperationExecutable, String)] = []
    var operationManager: OperationManager?  // ✅ Injected reference to OperationManager

    func handleException(_ operation: OperationExecutable, message: String) -> Bool {
        receivedExceptions.append((operation, message))

        print("🛑 MockExceptionHandler received exception: \(message) from \(operation.operationName)")

        // ✅ If the message contains "@return" or "non-critical", allow resumption.
        if message.contains("@return") || message.contains("non-critical") {
            Task {
                await operationManager?.addOperation(operation)  // ✅ Re-add operation
            }
            return true
        }

        return false  // ✅ Otherwise, operation does not resume.
    }

    /// ✅ Allows tests to verify exceptions were handled.
    func receivedExceptionCount() -> Int {
        return receivedExceptions.count
    }

    /// ✅ Allows tests to verify specific exception messages.
    func lastExceptionMessage() -> String? {
        return receivedExceptions.last?.1
    }
}

class MockWarningHandler: WarningHandler {
    var receivedWarnings: [(OperationExecutable, String)] = []

    func handleWarning(_ operation: OperationExecutable, message: String) {
        receivedWarnings.append((operation, message))
    }
}
