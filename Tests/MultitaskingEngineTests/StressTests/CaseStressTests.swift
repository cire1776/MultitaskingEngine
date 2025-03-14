//
//  CaseStressTests.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 3/2/25.
//

import Foundation
import Quick
import Nimble
@testable import MultitaskingEngine
@testable import TestHelpers

final class CaseStressTests: QuickSpec {
    override class func spec() {
        describe("Case Performancer Tests") {
            it("Can execute a million times performantly") {
                for index in 0..<255 {
                    executeFlowStep(index)
                }
            }
            
            it("can handle a million cases directly") {
                for step in 0..<256 {
                    switch step {
                    case 0: _ = "Initializing...".hashValue
                    case 1: _ = Array(0...100).shuffled()
                    case 2: _ = UUID().uuidString
                    case 3: _ = 42.isMultiple(of: 2)
                    case 4: _ = Data(count: 1024)
                    case 5...255: break
                    default: _ = "UNKNOWN".hashValue
                    }
                }
            }
            
            it("a empty loop to calculate context switching cost") {
                for step in 0..<256 {
                    _ = step
                }
            }
            
            it("a better empty loop of a million wihtout test overhead") {
                var dummyValue: UInt = 0  // ✅ Prevents loop removal

                let startTime = DispatchTime.now()

                for i in 0..<1_000_000 {
                    dummyValue &+= UInt(i)  // ✅ Ensures work is done (atomic-like effect)
                }

                let endTime = DispatchTime.now()
                let elapsedNanoseconds = Double(endTime.uptimeNanoseconds - startTime.uptimeNanoseconds)
                let opsPerSecond = 1_000_000 / (elapsedNanoseconds / 1_000_000_000)

                print("🔥 Executed 1,000,000 iterations in \(elapsedNanoseconds) ns (\(opsPerSecond) OPS)")
                print("Dummy Value (Ignore): \(dummyValue)")  // ✅ Prevents optimization
            }
            
            it("even better loop for a billiion times") {
                // ✅ Run inside high-priority Task
                Task(priority: .high) {
                    let iterations = 1_000_000_000  // **1 BILLION iterations**
                    var counter: UInt64 = 0  // ✅ Prevent compiler optimizations

                    let startTime = DispatchTime.now()

                    @inline(__always)  // ✅ Force inlining
                    func performWork(_ step: UInt64) {
                        counter &+= step  // ✅ Prevents optimization
                    }

                    for i in 0..<iterations {
                        performWork(UInt64(i))
                    }

                    let endTime = DispatchTime.now()
                    
                    let elapsedNanoseconds = Double(endTime.uptimeNanoseconds - startTime.uptimeNanoseconds)
                    let opsPerSecond = elapsedNanoseconds > 0 ? Double(iterations) / (elapsedNanoseconds / 1_000_000_000) : Double(iterations)

                    print("🔥 Executed \(iterations) iterations in \(elapsedNanoseconds) ns (\(opsPerSecond) OPS)")
                }
            }
        }
    }
}


func executeFlowStep(_ step: Int) {
    switch step {
    case 0:  print("Step 0: Initialization")
    case 1:  print("Step 1: Loading Data")
    case 2:  print("Step 2: Preprocessing Data")
    case 3:  print("Step 3: Validating Inputs")
    case 4:  print("Step 4: Establishing Connection")
    case 5:  print("Step 5: Sending Request")
    case 6:  print("Step 6: Receiving Response")
    case 7:  print("Step 7: Parsing Response")
    case 8:  print("Step 8: Error Handling - Minor Issue")
    case 9:  print("Step 9: Retrying Request")
    case 10: print("Step 10: Response Validated")
    case 11: print("Step 11: Storing Data")
    case 12: print("Step 12: Checking Dependencies")
    case 13: print("Step 13: Preparing UI Update")
    case 14: print("Step 14: Rendering UI")
    case 15: print("Step 15: Awaiting User Input")
    case 16: print("Step 16: Processing User Action")
    case 17: print("Step 17: Validating Action")
    case 18: print("Step 18: Triggering Side Effects")
    case 19: print("Step 19: Logging Action")
    case 20: print("Step 20: Notifying Other Components")
    case 21: print("Step 21: Committing Changes")
    case 22: print("Step 22: Synchronizing State")
    case 23: print("Step 23: Preparing Response")
    case 24: print("Step 24: Sending Response")
    case 25: print("Step 25: Cleanup Temporary Data")
    case 26: print("Step 26: Checking for Memory Leaks")
    case 27: print("Step 27: Finalizing Execution")
    case 28: print("Step 28: Flushing Logs")
    case 29: print("Step 29: Marking Task Complete")
    case 30: print("Step 30: Performing Garbage Collection")
    case 31: print("Step 31: Sleeping for Next Cycle")
    case 32...63: print("Step \(step): Running Background Tasks")
    case 64...127: print("Step \(step): Processing Async Events")
    case 128...191: print("Step \(step): Handling Parallel Execution")
    case 192...255: print("Step \(step): Wrapping Up Execution")
    default: print("Step \(step): UNKNOWN STEP — Terminating")
    }
}
