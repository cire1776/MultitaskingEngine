//
//  OperarionScheduler.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 3/1/25.
//

import Foundation
import Quick
import Nimble
@testable import MultitaskingEngine
@testable import TestHelpers

final class OperationSchedulerTests: AsyncSpec {
    override class func spec() {
        describe("OperationScheduler") {
            it("marks operations for yield if they exceed execution time limit") {
                let scheduler = OperationScheduler()
                let operation = MockOperation(operationName: "LongRunningOperation", states: [.initialization, .running])

                _ = await scheduler.addOperation(operation)

                // Simulate execution start
                _ = operation.execute()  // ✅ Transitions to .running
                operation.startTime = operation.startTime.advanced(by: Duration.nanoseconds(-100_000_000))

                await scheduler._schedule()
                
                expect(operation.executionFlags & ExecutionFlags.yield).to(equal(1))
            }
            
            it("removes completed and aborted operations while maintaining active ones") {
                let scheduler = OperationScheduler()

                let activeOp = MockOperation(operationName: "ActiveOperation", states: [.initialization, .running, .running])
                let completedOp = MockOperation(operationName: "CompletedOperation", states: [.initialization, .running, .completed])
                let abortedOp = MockOperation(operationName: "AbortedOperation", states: [.initialization,.running,.unusualExecutionEvent(.abort("Fatal error"))])
 
                _ = await scheduler.addOperation(activeOp)
                _ = await scheduler.addOperation(completedOp)
                _ = await scheduler.addOperation(abortedOp)
 
                // ✅ Limit loops to prevent infinite waiting
                var attempt = 0
                while activeOp.execute() != .running, attempt < 10 { attempt += 1 }
                attempt = 0
                while completedOp.execute() != .completed, attempt < 10 { attempt += 1 }
                attempt = 0
                while abortedOp.execute() != .unusualExecutionEvent(.abort("Fatal error")), attempt < 10 { attempt += 1 }
                attempt = 0
                await scheduler._schedule()

                let isCompletedOpInQueue = await scheduler._contains(completedOp)
                let isAbortedOpInQueue = await scheduler._contains(abortedOp)
                let isActiveOpInQueue = await scheduler._contains(activeOp)

                expect(isCompletedOpInQueue).to(beFalse())
                expect(isAbortedOpInQueue).to(beFalse())
                expect(isActiveOpInQueue).to(beTrue())  // ✅ Should still be in queue

                // ✅ Stop OS after the test
                await scheduler.stopNow()
            }
            
            it("scans and processes all active operations in queue") {
                let scheduler = OperationScheduler()

                let op1 = MockOperation(operationName: "Op1", states: [.running])
                let op2 = MockOperation(operationName: "Op2", states: [.running])
                let op3 = MockOperation(operationName: "Op3", states: [.initialization, .running])

                _ = await scheduler.addOperation(op1)
                _ = await scheduler.addOperation(op2)
                _ = await scheduler.addOperation(op3)

                // ✅ Ensure all operations execute at least once before OS processes them
                _ = op1.execute()
                _ = op2.execute()
                while op3.execute() != .running {}  // ✅ Transitions from suspended → running

                await scheduler._schedule()  // ✅ Now OS should correctly process active operations

                let isOp1Active = await scheduler._contains(op1)
                let isOp2Active = await scheduler._contains(op2)
                let isOp3Active = await scheduler._contains(op3)

                expect(isOp1Active).to(beTrue())  // ✅ Should still be in queue
                expect(isOp2Active).to(beTrue())  // ✅ Should still be in queue
                expect(isOp3Active).to(beTrue())  // ✅ Should still be in queue (after transitioning)
            }
            
            it("OS processes operations added by OM") {
                let scheduler = OperationScheduler()
                let manager = OperationManager(scheduler: scheduler)

                let op = MockOperation(operationName: "ScheduledOp", states: [.running, .completed])

                _ = await manager.addOperation(op)
                await manager.pump()

                await scheduler._schedule()  // ✅ OS processes the operation

                let isStillInOSQueue = await scheduler._contains(op)

                expect(isStillInOSQueue).to(beFalse())  // ✅ OS should remove completed operations
                
                await manager.stopNow()
            }
        }
    }
}
