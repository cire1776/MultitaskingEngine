//
//  exceptions.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 2/28/25.
//

protocol ExceptionHandler: Actor {
    func handleException(_ operation: OperationExecutable, message: String) async -> Bool
}

actor ExceptionHandlerActor: ExceptionHandler {
    func handleException(_ operation: OperationExecutable, message: String) async -> Bool {
        logger.log(level: LogLevel.info, message: "MTE Exception in operation \(operation.operationName): \(message)")
        
        // Simulated async logging
        try! await Task.sleep(nanoseconds: 500_000_000)
        
        return message.contains("non-critical")
    }
}

protocol WarningHandler {
    func handleWarning(_ operation: OperationExecutable, message: String)
}

struct MTEWarningHandler: WarningHandler {
    func handleWarning(_ operation: OperationExecutable, message: String) {
        logger.log(level: LogLevel.warn, message: "⚠️ Warning from \(operation.operationName): \(message)")
    }
}


