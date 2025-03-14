//
//  StressTests.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 3/1/25.
//
import Foundation

import Quick
import Nimble
@testable import MultitaskingEngine
@testable import TestHelpers
import Atomics

final class StressTests: AsyncSpec {
    override class func spec() {
        xit("handles 100,000 operations efficiently") {
            var scheduler: OperationScheduler? = OperationScheduler()
            var manager: OperationManager? = OperationManager(queueSize: 200_000, scheduler: scheduler!)
            let totalOperations = 100_000

//            Task {
//                for i in 0..<totalOperations {
//                    let op = MockOperation(operationName: "Task-\(i)", states: [.running, .completed])
//                    if !(await manager.addOperation(op)) {
//                        print("Failed to add operation")
//                    }
//                    
//                    if i % 10_000 == 0 {
//                        print("📌 Added \(i) operations so far")
//                    }
//                }
//            }
            
            for i in 0..<totalOperations {
                let op = MockOperation(operationName: "Task-\(i)", states: [.running, .completed])
                await manager?.addOperation(op)
            }
            await print("📌 All 100,000 operations added. Queue size: \(manager?.calculateQueueSize())")
            
            await manager?.pump(times: 100_000)

            print("Done with manager.")

            let managerRef = manager  // ✅ Capture the reference first

            let (times) = await Task {
                let startTime = DispatchTime.now()

                while await managerRef?.calculateQueueSize() ?? 0 < 1000 {
                    await Task.yield()  // ✅ Ensures OM doesn't start too early
                }

                await managerRef?.pump(times: 100_000)  // ✅ Now `pump()` starts only after enough operations exist
                let endTime = DispatchTime.now()
                return (startTime, endTime)
            }.value
            
            print("⏳ Checking for active tasks before exit...")
            
            await manager?.stopNow()
            await scheduler?.stopNow()

            print("🚀 OM and OS stopped. Clearing references...")
            manager = nil
            scheduler = nil  // ✅ This should allow ARC to release both actors

            print("✅ OM and OS fully deallocated."); fflush(stdout)
            
            let elapsedNanoseconds = Double(times.1.uptimeNanoseconds - times.0.uptimeNanoseconds)  // ✅ Use uptimeNanoseconds directly

            let opsPerSecond = elapsedNanoseconds > 0
                ? Double(totalOperations) / (elapsedNanoseconds / 1_000_000_000)
                : Double(totalOperations)
            
            print("🔥 Processed \(totalOperations) operations in \(elapsedNanoseconds) ns (\(opsPerSecond) OPS)")
            
            expect(completedOperations.load(ordering: .relaxed)).to(equal(totalOperations))
        }
    }
}
