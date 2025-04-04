//
//  unusual_execution_event.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 3/7/25.
//

public enum UnusualExecutionEvent: Sendable, Equatable {
    case warning(String)     // ⚠️ Informational; execution continues naturally
    case exception(String)   // 🔶 Structured error; recovery depends on UUES handlers
    case abort(String)       // ❌ Execution stops immediately, no recovery
}

protocol UUESHandling {
    func handleUnusualEvent(_ event: UnusualExecutionEvent)
}

final class DefaultUUESHandler: UUESHandling {
    func handleUnusualEvent(_ event: UnusualExecutionEvent) {
        switch event {
        case .warning(let message):
            print("⚠️ [Warning] \(message) - Execution continues.")
        case .exception(let message):
            print("❌ [Failure] \(message) - Operation will stop.")
        case .abort(let message):
            fatalError("🚨 [Abort] \(message) - System execution terminated.")
        }
    }
}
