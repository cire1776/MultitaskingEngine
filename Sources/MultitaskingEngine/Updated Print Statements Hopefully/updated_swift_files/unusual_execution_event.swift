//
//  unusual_execution_event.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 3/7/25.
//

enum UnusualExecutionEvent {
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
            logger.log(level: LogLevel.warn, message: "⚠️ [Warning] \(message) - Execution continues.")
        case .exception(let message):
            logger.log(level: LogLevel.info, message: "❌ [Failure] \(message) - Operation will stop.")
        case .abort(let message):
            fatalError("🚨 [Abort] \(message) - System execution terminated.")
        }
    }
}
