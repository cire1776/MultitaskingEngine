//
//  operationTests.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 2/28/25.
//

import Quick
import Nimble
@testable import MultitaskingEngine
@testable import TestHelpers

class operationManagerTests: AsyncSpec {
    override class func spec() {
        describe("OperationManager") {
            it("executes normally") {
                let operation = MockOperation(operationName: "NormalOperation", states: [.running])
                
                let result = operation.execute()
                
                expect(result).to(equal(.running))
            }
            
            it("executes in multiple steps before completion") {
                let operation = MockOperation(operationName: "MultiStepOperation", states: [.firstRun, .running, .completed])
                
                expect(operation.execute()).to(equal(.firstRun))
                expect(operation.execute()).to(equal(.running))
                expect(operation.execute()).to(equal(.completed))
            }
            
            it("suspends and resumes execution") {
                let operation = MockOperation(operationName: "SuspendingOperation", states: [.firstRun, .suspended, .running, .completed])
                
                expect(operation.execute()).to(equal(.firstRun))  // First step: running
                expect(operation.execute()).to(equal(.suspended))  // Second step: suspends
                expect(operation.execute()).to(equal(.running))  // Resumes execution
                expect(operation.execute()).to(equal(.completed))  // Completes
            }
            
            it("returns a warning message") {
                let operation = MockOperation(operationName: "WarningOperation", states: [.firstRun, .unusualExecutionEvent(.warning("Low disk space")), .completed])
                
                expect(operation.execute()).to(equal(.firstRun))
                expect(operation.execute()).to(equal(.unusualExecutionEvent(.warning("Low disk space"))))
                expect(operation.execute()).to(equal(.completed))
            }
            
            it("stops execution when a fatal exception occurs") {
                let mockExceptionHandler = MockExceptionHandler()
                let manager = OperationManager(exceptionHandler: mockExceptionHandler, warningHandler: MTEWarningHandler())
                
                let operation = MockOperation(operationName: "FatalExceptionOperation", states: [
                    .firstRun,
                    .unusualExecutionEvent(.exception("Critical error")),
                    .running,
                    .completed
                ])
                
                _ = await manager.addOperation(operation)
                
                _ = await manager.pump(retries: 1000) {
                    await Task { await mockExceptionHandler.receivedExceptions.count > 0 }.value
                }
                let count = await mockExceptionHandler.receivedExceptions.count
                expect(count).to(equal(1))
            }
            
            it("aborts execution with a message") {
                let operation = MockOperation(operationName: "AbortOperation", states: [.firstRun, .unusualExecutionEvent(.abort("Critical system failure"))])
                
                expect(operation.execute()).to(equal(.firstRun))
                expect(operation.execute()).to(equal(.unusualExecutionEvent(.abort("Critical system failure"))))
            }
            
            it("OM adds operations to OS when they start") {
                let scheduler = OperationScheduler()
                let manager = OperationManager(scheduler: scheduler)
                
                let op = MockOperation(operationName: "OMTask", states: [.firstRun, .running])
                
                _ = await manager.addOperation(op)
                await scheduler._schedule()
                
                await manager.pump()
                
                let isInOSQueue = await scheduler._contains(op)
                
                expect(isInOSQueue).to(beTrue())  // ✅ OM should add operation to OS when it starts
                
                await manager.stopNow()
            }
            
            it("updates operation state from .firstRun to .running before execution") {
                let manager = OperationManager()  // ✅ Create OM instance
                let operation = MockOperation(operationName: "TestFirstRun", states: [
                    .firstRun,  // ✅ Starts in firstRun
                    .running,   // ✅ This must be explicitly tested
                    .completed  // ✅ Should eventually complete
                ])
                
                _ = await manager.addOperation(operation)
                
                _ = await manager.pump(retries: 10) {
                    operation.state == .running
                }
                
                expect(operation.state).to(equal(.running))  // ✅ Now we actually capture .running
                
                let retries = await manager.pump(retries: 10) {
                    operation.state == .completed
                }
                
                expect(operation.state).to(equal(.completed))
                
                await manager.stopNow()
            }
        }
    }
}
