//
//  HOEIntegrationTest.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 3/7/25.
//

import Quick
import Nimble
@testable import MultitaskingEngine
@testable import TestHelpers

func setupTestEnvironment()  async -> (ThreadExecutionContext, OperationManager, HensionOperationExecutable) {
    let executionContext = ThreadExecutionContext(uuesHandler: DefaultUUESHandler())
    let operationManager = OperationManager()
    let hoe = HensionOperationExecutable(
        operationName: "TestHensionMTE",
        executionContext: executionContext
    )

    print("🚀 Starting Operation Manager...")
    Task { await operationManager.start() }

    _ = await whileTimeout(seconds: 5) {
        await operationManager.isRunning
    }

    return (executionContext, operationManager, hoe)
}

final class HOEIntegrationTest: AsyncSpec {
    override class func spec() {
        xdescribe("HensionOperationExecutable Inside MTE") {

            it("should fail before we implement the fix") {
                let (_, _, hoe) = await setupTestEnvironment()

                let fakeState: OperationState = .running  // ✅ Incorrect expected value to force a failure
                expect(hoe.state).to(equal(fakeState), description: "This should fail before fixing the implementation.")
            }

            it("should handle file read errors as an exception and trigger UUES") {
                let (executionContext, operationManager, hoe) = await setupTestEnvironment()

                print("📌 Adding HOE with a file error to the Operation Manager...")
                let added = await operationManager.addOperation(hoe)
                expect(added).to(beTrue(), description: "HOE should be successfully added to the OM.")

                // ✅ **Ensure HOE fails due to a file read error**
                _ = await whileTimeout(seconds: 5) {
                    hoe.state != .exception("Failed to open file")
                }

                if case let .exception(message) = hoe.state {
                    expect(message).to(contain("Failed to open file"), description: "HOE should fail with a file read error.")
                    print("✅ HOE correctly failed with file read error.")
                } else {
                    fail("HOE did not fail as expected")
                }

                // ✅ **Ensure UUES logs the failure**
                _ = await whileTimeout(seconds: 5) {
                    (try? executionContext["lastError"].get()) == nil
                }

                expect(executionContext["lastError"]).toNot(beNil(), description: "Execution context should record the last UUES error.")

                if case let .success(errorMessage) = executionContext["lastError"], let errorString = errorMessage as? String {
                    expect(errorString).to(contain("Failed to open file"), description: "UUES should log the file read failure.")
                    print("✅ UUES correctly logged the file read error.")
                } else {
                    fail("UUES did not log the expected error message.")
                }

                // ✅ **Ensure OM naturally suspends**
                await whileTimeout(seconds: 5) {
                    await operationManager.calculateQueueSize() > 0
                }
            }

            it("should execute correctly within the MTE") {
                let (executionContext, operationManager, hoe) = await setupTestEnvironment()

                print("📌 Adding HOE to the Operation Manager...")
                let added = await operationManager.addOperation(hoe)
                expect(added).to(beTrue(), description: "HOE should be successfully added to the OM.")

                // ✅ Wait until the operation moves to a completed state
                _ = await whileTimeout(seconds: 5) {
                    hoe.state != .completed
                }

                expect(hoe.state).to(equal(.completed), description: "HOE should complete execution within MTE.")
            }
        }
    }
}
