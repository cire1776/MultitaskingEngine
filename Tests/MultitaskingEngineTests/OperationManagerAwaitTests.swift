//
//  OperationManagerAwaitTests.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 4/4/25.
//

import Quick
import Nimble
@testable import MultitaskingEngine
@testable import TestHelpers

final class OperationManagerAwaitTests: AsyncSpec {
    override class func spec() {
        describe("OperationManager Await Handling") {
            var om: OperationManager!
            var dummyOperation: MockOperation!  // Our test operation
            
            beforeEach {
                // Create a new OperationManager for each test.
                om = OperationManager()
                // Create a dummy operation starting in the .running state.
                dummyOperation = MockOperation(operationName: "TestOperation", states: [.running])
                _ = dummyOperation.execute()
                _ = await om.addOperation(dummyOperation)
            }
            
            context("proper usage") {
                it("sets a running operation to .awaiting when addAwait is called") {
                    await om.addAwait(dummyOperation)
                    expect(dummyOperation.state).to(equal(.awaiting))
                }
                
                it("resumes an awaiting operation to .running when awaitDone is called") {
                    await om.addAwait(dummyOperation)
                    try? await Task.sleep(nanoseconds: 10_000)
                    await om.awaitDone(dummyOperation)
                    expect(dummyOperation.state).to(equal(.running))
                }
            }
            
            context("improper usage: addAwait called on an operation that is not running") {
                it("reports an error if addAwait is called on a completed operation") {
                    // Simulate a completed operation.
                    dummyOperation.state = .completed
                    // When addAwait is called, the OM should detect the misuse.
                    await om.addAwait(dummyOperation)
                    // Here we expect that dummyOperation.state becomes an unusual event with an appropriate error.
                    expect(dummyOperation.state)
                        .to(equal(.unusualExecutionEvent(.exception("~ULang internal~: Operation not running"))))
                }
            }
            
            context("improper usage: awaitDone called on an operation not in .awaiting state") {
                it("reports an error if awaitDone is called when the operation is not awaiting") {
                    // Ensure the operation is not in .awaiting (say, still running).
                    dummyOperation.state = .running
                    await om.awaitDone(dummyOperation)
                    // We expect the OM to flag this as an error.
                    expect(dummyOperation.state)
                        .to(equal(.unusualExecutionEvent(.exception("~ULang internal~: Operation not awaiting"))))
                }
            }
            
            context("queue management during await") {
                it("removes an operation from the queue when addAwait is called") {
                    // Confirm the operation is queued initially.
                    var result = await om.isQueued(dummyOperation)
                    expect(result).to(beTrue())
                    
                    await om.addAwait(dummyOperation)
                    // After addAwait, the operation should be removed from the queue.
                    result = await om.isQueued(dummyOperation)
                    expect(result).to(beFalse())
                }
                
                it("re-adds an operation to the queue when awaitDone is called") {
                    // Set the operation to awaiting first.
                    await om.addAwait(dummyOperation)
                    // Confirm it's removed from the queue.
                    var result = await om.isQueued(dummyOperation)
                    expect(result).to(beFalse())
                    
                    // Allow a brief pause to simulate an asynchronous gap.
                    try? await Task.sleep(nanoseconds: 10_000)
                    await om.awaitDone(dummyOperation)
                    // After awaitDone, the operation should be re-queued.
                    result = await om.isQueued(dummyOperation)
                    expect(result).to(beTrue())
                }
            }
        }
    }
}
