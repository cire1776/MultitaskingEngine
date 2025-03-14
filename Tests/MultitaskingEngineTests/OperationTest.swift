//
//  OperationTest.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 3/1/25.
//
import Quick
import Nimble
@testable import MultitaskingEngine
@testable import TestHelpers

final class OperationTest: AsyncSpec {
    override class func spec() {
        it("updates state to .completed after execution") {
            let operation = MockOperation(operationName: "CompletingOperation", states: [.running, .completed])
            
            /// state is initial suspended
            expect(operation.state).to(equal(.suspended))
            
            _ = operation.execute()
            expect(operation.state).to(equal(.running))
            
            _ = operation.execute()
            
            expect(operation.state).to(equal(.completed))  // ✅ Should now be .completed
            
            
        }
        
        xit("should execute without the OM and store output in the EC") {
            let executionContext = ThreadExecutionContext()
            
            let hensionOp = HensionOperationExecutable(
                operationName: "TestHensionStandalone",
                executionContext: executionContext
            )
            
            print("📌 Running HensionOperation standalone...")
            let result = hensionOp.execute()
            
            // ✅ Ensure operation completes successfully
            expect(result).to(equal(.completed), description: "HensionOperation should complete execution.")
            
            // ✅ Ensure output exists inside EC
            expect(executionContext["output"]).toNot(beNil(), description: "Execution context should contain an output variable.")
            
            // ✅ Ensure at least some data was processed
            if case let .success(output) = executionContext["output"], let outputArray = output as? [String] {
                expect(outputArray.isEmpty).to(beFalse(), description: "Output should not be empty")
                print("✅ Standalone execution successful, output contains data.")
            } else {
                fail("Execution context output is missing or malformed")
            }
        }
        
    }
}
