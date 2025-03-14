//
//  ExceptionTests.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 2/28/25.
//
import Quick
import Nimble
@testable import MultitaskingEngine
@testable import TestHelpers


final class ExceptionTests: AsyncSpec {
    override class func spec() {
        it("resumes operation execution after a recoverable exception using MTE default handler") {
            let exceptionHandler = MockExceptionHandler()  // MTE default
            let manager = OperationManager(exceptionHandler: exceptionHandler)
            
            let operation = MockOperation(operationName: "RecoverableOperation", states: [
                .firstRun,
                .exception("non-critical issue"),  // Default handler should resume
                .running,
                .completed
            ])
            
            _ = await manager.addOperation(operation)

            var retries = 0
            
            while operation.state != .completed, retries < 10 {
                await manager.pump()
                try await Task.sleep(nanoseconds: 100_000_000)
                retries += 1
            }
            expect(retries).to(beLessThan(10))
            expect(operation.state).to(equal(.completed))
            
            await manager.stopNow()
        }
        
        it("does not resume execution after a critical exception in MTE default handler") {
            let exceptionHandler = ExceptionHandlerActor()
            let manager = OperationManager(exceptionHandler: exceptionHandler)
            
            let operation = MockOperation(operationName: "FatalOperation", states: [
                .firstRun,
                .exception("critical failure"),  // Default handler should stop operation
                .running,
                .completed
            ])
            
            _ = await manager.addOperation(operation)
            
            await manager.pump(times: 6)
            
            expect(operation.execute()).toNot(equal(.completed))
            
            await manager.stopNow()
        }
        
        it("ULang's exception handler resumes execution for ULang-recoverable errors") {
            actor ULangExceptionHandler: ExceptionHandler {
                func handleException(_ operation: OperationExecutable, message: String) -> Bool {
                    return message.contains("ULang-recoverable")  // Custom rule for ULang
                }
            }
            
            let exceptionHandler = ULangExceptionHandler()  // ULang-specific handler
            let manager = OperationManager(exceptionHandler: exceptionHandler)
            
            let operation = MockOperation(operationName: "ULangSpecialOperation", states: [
                .firstRun,
                .exception("ULang-recoverable"),  // ULang handler should allow resumption
                .running,
                .completed
            ])
            
            _ = await manager.addOperation(operation)

            let retries = await manager.pump(retries: 1000) {
                operation.state == .completed
            }
            
            expect(retries).to(beLessThan(1000))
            
            // ✅ Use helper function to wait for operation completion
//            await waitForCondition {  }

            expect(operation.state).to(equal(.completed))  // ✅ Ensure operation actually completed
            
            await manager.stopNow()
        }
        
        it("throws a returnable exception and continues") {
            let operation = MockOperation(operationName: "ReturnableExceptionOperation", states: [.firstRun, .exception("Minor failure @return"), .completed])

            expect(operation.execute()).to(equal(.firstRun))
            expect(operation.execute()).to(equal(.exception("Minor failure @return")))  // Exception occurs
            expect(operation.execute()).to(equal(.completed))  // operation can still finish
        }

    }
}
