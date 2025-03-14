//
//  operation_schedular.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 3/1/25.
//

import Foundation

protocol OperationScheduling: AnyObject, Sendable {
    func addOperation(_ operation: any OperationExecutable) async -> Bool
#if DEBUG
    func _schedule() async  // ✅ Only available in debug builds
    func _contains(_ operation: OperationExecutable) async-> Bool
#endif
}


actor OperationScheduler: OperationScheduling {
    private var activeQueue: [OperationExecutable?] = []
    
#if DEBUG
    func _schedule() async {
        await scanOperations()
    }
    
    func _contains(_ operation: OperationExecutable) -> Bool {
        guard !activeQueue.isEmpty else { return false }  // ✅ Prevents division by zero
        
        var index = head
        
        while index != tail {
            if let op = activeQueue[index], op === operation {
                return true  // ✅ Found the operation in the queue
            }
            index = (index + 1) % activeQueue.count  // ✅ Safe modulo operation
        }
        
        return false 
    }
#endif
    
    private let queueSize: Int
    private var head: Int = 0
    private var tail: Int = 0
    private var isRunning = false
    private let maxExecutionTime: Duration = .milliseconds(50)  // ✅ 50ms max execution per OE
    
    init(queueSize: Int = 10_000) {
        self.queueSize = queueSize
        self.activeQueue = Array(repeating: nil, count: queueSize)
    }
    
    func addOperation(_ operation: any OperationExecutable) async -> Bool {
        let nextTail = (tail + 1) % queueSize
        
        if nextTail == head {
            logger.log(level: LogLevel.info, message: "⚠️ OS Queue full! Cannot track operation: \(operation.operationName)")
            return false
        }
        
        activeQueue[tail] = operation
        tail = nextTail
        
        return true
    }
    
    func start() async {
        guard !isRunning else { return }
        isRunning = true
        logger.log(level: LogLevel.info, message: "🚀 OperationScheduler started")
        
        while isRunning {
            if head == tail {
                logger.log(level: LogLevel.info, message: "⚠️ No operations need yielding, suspending OS...")
            }
            await scanOperations()
        }
    }
    
    private func scanOperations() async {
        var index = self.head        
        var newQueue: [OperationExecutable?] = Array(repeating: nil, count: queueSize)
        var newTail = 0

        while index != tail {
            guard let operation = activeQueue[index] else {
                index = (index + 1) % queueSize
                continue
            }

            let elapsedTime = operation.startTime.duration(to: ContinuousClock.now).components.seconds * 1_000 +
                              operation.startTime.duration(to: ContinuousClock.now).components.attoseconds / 1_000_000

            let maxExecutionMs = maxExecutionTime.components.seconds * 1_000 +
                                 maxExecutionTime.components.attoseconds / 1_000_000

            if elapsedTime >= maxExecutionMs {  // ✅ Now both values are in milliseconds
                operation.executionFlags |= ExecutionFlags.yield  // ✅ Mark for yielding
                logger.log(level: LogLevel.info, message: "⏳ Marking \(operation.operationName) for yield (Ran \(elapsedTime)ms)")
            }
            // ✅ Only keep operations that aren't completed or aborted
            switch operation.state {
            case .completed, .abort(_), .suspended:
                break
                // Skip adding this operation to the new queue
            default:
                newQueue[newTail] = operation
                newTail = (newTail + 1) % queueSize
            }

            index = (index + 1) % queueSize
        }

        // ✅ Update queue references
        activeQueue = newQueue
        tail = newTail
    }
    
    public func stopNow() {
        self.isRunning = false
        head = tail
        activeQueue = Array(repeating: nil, count: queueSize)
    }
}
