//
//  ModelHensionSubscriptionIntegrationTests.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 3/27/25.
//

import Foundation
import Quick
import Nimble
@testable import MultitaskingEngine
@testable import TestHelpers

final class ModelHensionSubscriptionIntegrationTests: AsyncSpec {
    override class func spec() {
        describe("Model Hension Blueprint Instantiation and Execution using ManualLintRunner") {
            var executionContext: SubscriptionStreamExecutionContext!
            var blueprint: Comprehension_S_1A5D27B4!
            var modelInstance: Comprehension.Instance!
            var runner: ManualLintRunner!
            let testDir = "/tmp/model-hension1"
            
            beforeEach {
                // Setup a fresh execution context for each test.
                executionContext = SubscriptionStreamExecutionContext()
                
                // Create the test directory and sample files.
                try? FileManager.default.createDirectory(atPath: testDir, withIntermediateDirectories: true)
                try? "alpha".write(toFile: "\(testDir)/a.txt", atomically: true, encoding: .utf8)
                try? "bravo".write(toFile: "\(testDir)/b.txt", atomically: true, encoding: .utf8)
                try? "skip me".write(toFile: "\(testDir)/output.txt", atomically: true, encoding: .utf8)
                
                // Instantiate the blueprint (Comprehension_S_1A5D27B4 is the blueprint).
                blueprint = Comprehension_S_1A5D27B4(executionContext: executionContext)
            }
            
            afterEach {
                do {
                    try FileManager.default.removeItem(atPath: testDir)
                    print("Folder deleted successfully.")
                } catch {
                    print("Error deleting folder: \(error)")
                }
            }
            
            context("when instantiated with a preinitialization lint") {
                beforeEach {
                    // Instantiate a model hension instance from the blueprint,
                    // passing a preinitialization lint that sets 'baseDir'.
                    modelInstance = blueprint.instantiate(preinitialization_specifier: LintSpecifier({ _ in
                        executionContext.ensure("baseDir",defaultValue: testDir)
                        return .firstRun
                    }), executionContext: executionContext)
                    
                    // Create a ManualLintRunner to execute the hension.
                    runner = ManualLintRunner(provider: modelInstance)
                }
                
                it("executes the full lint chain on first run and correctly injects baseDir") {
                    let result = await runner.executeAll()
                    expect(result).to(equal(.completed))
                    
                    // Verify that the preinitialization lint injected baseDir into the execution context.
                    let baseDir = try? executionContext["baseDir"].get() as? String
                    expect(baseDir).to(equal(testDir))
                }
                
                it("on subsequent executions, only the run lint is executed while preserving baseDir") {
                    // First execution runs the full lint chain.
                    _ = await runner.executeAll()
                    
                    // Capture the injected baseDir after the first run.
                    let firstBaseDir = try? executionContext["baseDir"].get() as? String
                    expect(firstBaseDir).to(equal(testDir))
                    
                    // Subsequent execution should only run the run lint.
                    let secondResult = await runner.executeAll()
                    expect(secondResult).to(equal(.completed))
                    
                    // Confirm that the baseDir injection remains unchanged.
                    let secondBaseDir = try? executionContext["baseDir"].get() as? String
                    expect(secondBaseDir).to(equal(testDir))
                }
            }
        }
        
        describe("Model Hension Blueprint Instantiation and Execution using Operation Runner") {
            var executionContext: SubscriptionStreamExecutionContext!
            var blueprint: Comprehension_S_1A5D27B4!
            var modelInstance: Comprehension.Instance!
            var operation: MultitaskingEngine.Operation!
            let testDir = "/tmp/model-hension"
            
            beforeEach {
                // Setup a fresh execution context for each test.
                executionContext = SubscriptionStreamExecutionContext()
                
                // Create the test directory and sample files.
                try? FileManager.default.createDirectory(atPath: testDir, withIntermediateDirectories: true)
                try? "alpha".write(toFile: "\(testDir)/a.txt", atomically: true, encoding: .utf8)
                try? "bravo".write(toFile: "\(testDir)/b.txt", atomically: true, encoding: .utf8)
                try? "skip me".write(toFile: "\(testDir)/output.txt", atomically: true, encoding: .utf8)
                
                // Instantiate the blueprint Comprehension_S_1A5D27B4 is the blueprint).
                blueprint = Comprehension_S_1A5D27B4(executionContext: executionContext)
            }
            
            afterEach {
                do {
                    try FileManager.default.removeItem(atPath: testDir)
                    print("Folder deleted successfully.")
                } catch {
                    print("Error deleting folder: \(error)")
                }
            }
            
            context("when instantiated with a preinit injection") {
                beforeEach {
                    // Instantiate the model hension instance from the blueprint,
                    // providing a preinitialization lint that injects the baseDir.
                    modelInstance = blueprint.instantiate(preinitialization_specifier: LintSpecifier({ _ in
                        executionContext.ensure("baseDir",defaultValue:  testDir)
                        return .firstRun
                    }), executionContext: executionContext)
                    
                    // Create an Operation from the instance's lints.
                    // The Operation initializer takes the operation name, an execution context, and an array of lint closures.
                    operation = Operation(name: "TestModelHension", provider: modelInstance)
                }
                
                it("executes the full lint chain on first run and correctly injects baseDir") {
                    let result = await operation.execute()
                    expect(result).to(equal(.completed))
                    
                    // Verify that the preinitialization lint injected baseDir into the execution context.
                    let baseDir = try? executionContext["baseDir"].get() as? String
                    expect(baseDir).to(equal(testDir))
                }
                
                it("on subsequent executions, only the run lint is executed while preserving baseDir") {
                    // First execution runs full lint chain.
                    _ = await operation.execute()
                    
                    // Capture the injected baseDir after the first run.
                    let firstBaseDir = try? executionContext["baseDir"].get() as? String
                    expect(firstBaseDir).to(equal(testDir))
                    
                    // Subsequent execution should only run the run lint.
                    let secondResult = await operation.execute()
                    expect(secondResult).to(equal(.completed))
                    
                    // Confirm that the baseDir injection remains unchanged.
                    let secondBaseDir = try? executionContext["baseDir"].get() as? String
                    expect(secondBaseDir).to(equal(testDir))
                }
            }
        }
        
        func setupTestEnvironment()  async -> OperationManager {
            let operationManager = OperationManager()

            print("🚀 Starting Operation Manager...")
            Task { await operationManager.start() }

            _ = await whileTimeout(seconds: 5) {
                await operationManager.isRunning
            }

            return operationManager
        }
        
        describe("Model Hension Integration using OperationManager") {
            var executionContext: SubscriptionStreamExecutionContext!
            var blueprint: Comprehension_S_1A5D27B4!
            var modelInstance: Comprehension.Instance!
            var operation: MultitaskingEngine.Operation! // Fully qualified to avoid ambiguity.
            var operationManager: OperationManager!
            let testDir = "/tmp/model-hension-OM-test"
            
            beforeEach {
                operationManager = await setupTestEnvironment()
                
                // Create a fresh execution context for each test.
                executionContext = SubscriptionStreamExecutionContext()
                
                // Set up test directory and sample files.
                try? FileManager.default.createDirectory(atPath: testDir, withIntermediateDirectories: true)
                try? "alpha".write(toFile: "\(testDir)/a.txt", atomically: true, encoding: .utf8)
                try? "bravo".write(toFile: "\(testDir)/b.txt", atomically: true, encoding: .utf8)
                try? "skip me".write(toFile: "\(testDir)/output.txt", atomically: true, encoding: .utf8)
                
                // Instantiate the blueprint (Comprehension_S_1A5D27B4 is our blueprint).
                blueprint = Comprehension_S_1A5D27B4(executionContext: executionContext)
                
                // Instantiate a model hension instance from the blueprint,
                // providing a preinitialization lint that injects 'baseDir'.
                modelInstance = blueprint.instantiate(preinitialization_specifier: LintSpecifier({ _ in
                    executionContext.ensure("baseDir",defaultValue: testDir)
                    return .firstRun
                }), executionContext: executionContext)
                
                // Create an Operation from the instance's lint array.
                operation = MultitaskingEngine.Operation(
                    name: "ModelHensionTest",
                    provider: modelInstance
                )
            }
            
            afterEach {
                await operationManager.stopNow()
                
                // Cleanup: Remove the test directory and its contents.
                try? FileManager.default.removeItem(atPath: testDir)
            }
            
            it("executes the model hension via the OperationManager and correctly injects baseDir") {
                // Add the operation to the OperationManager and run it.
                _ = await operationManager.addOperation(operation)
                
                let op = operation!
                
                _ = await whileTimeout(seconds: 5) {
                    op.state == .completed
                }
                
                expect(operation.state).to(equal(.completed))
                
                // Verify that the preinitialization lint injected baseDir into the execution context.
                let baseDir = try? executionContext["baseDir"].get() as? String
                expect(baseDir).to(equal(testDir))
            }
        }
    }
}
