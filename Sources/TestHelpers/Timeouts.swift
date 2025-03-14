//
//  Timeouts.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 3/8/25.
//
import Foundation

public func withTimeout(seconds: Double, operation: @Sendable @escaping () async -> Void) async {
    let didFinish = await withTaskGroup(of: Bool.self) { group in
        group.addTask {
            await operation()
            return true
        }
        
        group.addTask {
            try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            return false
        }
        
        let result = await group.reduce(false) { $0 || $1 }
        
        return result
    }

    if didFinish {
        print("🏁 timeout didnt trigger. ")
    }
    
    if !didFinish {
        fatalError("❌ Test timed out after \(seconds) seconds")
    }
}

actor Status {
    var stopped = false
    
    public func stop() {
        stopped =  true
    }
}
 
public func whileTimeout(
    seconds: Double,
    condition: @Sendable @escaping () async -> Bool
) async -> Bool {
//    var conditionTask: Task<Bool,Never>!=nil
    let status = Status()
    
    // ✅ Define tasks BEFORE adding them to the group
    let timeoutTask = Task {
        let deadline = Date().addingTimeInterval(seconds)
        while Date().timeIntervalSince(deadline) < 0  {
            let stopped = await status.stopped
            if Task.isCancelled || stopped { return false }  // ✅ Stop early if cancelled
            try? await Task.sleep(nanoseconds: 5_000_000) // ✅ Reduce CPU load
        }
        await status.stop()
        return false // ✅ Timeout reached
    }

    let conditionTask = Task {
        while !Task.isCancelled {  // ✅ Ensure cancellation exits the loop
            if await status.stopped { break }
            if await condition() {
                return true // ✅ Condition met, return early
            }
            await Task.yield() // ✅ Prevent blocking
        }
        await status.stop()
        return false // ✅ If cancelled, return false
    }

    // ✅ Run both tasks in a TaskGroup
    let didFinish = await withTaskGroup(of: Bool.self) { group in
        group.addTask { await conditionTask.value }
        group.addTask { await timeoutTask.value }
        
        
        return await group.reduce(false) { $0 || $1 } // ✅ Returns first `true`
        await status.stop()
    }

    // ✅ Explicitly cancel both tasks after determining result
    timeoutTask.cancel()
    conditionTask.cancel()

    return didFinish
}
