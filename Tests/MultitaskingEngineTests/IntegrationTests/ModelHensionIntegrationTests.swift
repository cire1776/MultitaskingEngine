//
//  ModelHensionIntegrationTests.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 3/27/25.
//

import Foundation
import Quick
import Nimble
@testable import MultitaskingEngine
@testable import TestHelpers

final class ModelHensionIntegrationTests: AsyncSpec {
    override class func spec() {
        describe("model hension integration") {
            var executionContext: StreamExecutionContext!
            
            beforeEach {
                executionContext = StreamExecutionContext()
            }
            
            it("step 1: reads file names from directory") {
                // ✅ Setup
                let dir = "/tmp/model-hensions"
                try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
                try? "alpha".write(toFile: "\(dir)/a.txt", atomically: true, encoding: .utf8)
                try? "bravo".write(toFile: "\(dir)/b.txt", atomically: true, encoding: .utf8)
                try? "skip me".write(toFile: "\(dir)/output.txt", atomically: true, encoding: .utf8)
                
                // ✅ Execution
                let readFiles = ReadFiles(aliasMap: ["output": "filename"], executionContext: executionContext)
                
                executionContext["baseDir"] = .success(dir)
                
                readFiles.initialize()
                
                expect(readFiles.next()).to(equal(.proceed))
                expect(readFiles.next()).to(equal(.proceed))
                expect(readFiles.next()).to(equal(.proceed))
                expect(readFiles.next()).to(equal(.eof))
            }
            
            it("step 2: skips 'output.txt' and allows others through") {
                let filenames = ["data1.txt", "output.txt", "data2.txt"]
                let skip = SkipFilter(
                    valuesToSkip: ["output.txt"],
                    stream: "filename",
                    executionContext: executionContext
                )
                
                for name in filenames {
                    executionContext["filename"] = .success(name)
                    let result = skip.include()
                    
                    if name == "output.txt" {
                        expect(result).to(equal(.notAvailable))
                    } else {
                        expect(result).to(equal(.proceed))
                    }
                }
            }
            
            it("step 3: delegates to process_file hension") {
                executionContext["filename"] = .success("/tmp/sample.txt")
                try? "data".write(toFile: "/tmp/sample.txt", atomically: true, encoding: .utf8)
                
                let processFile = Comprehension_ProcessFile(
                    executionContext: executionContext
                )
                
                expect(processFile.execute()).to(equal(.proceed))
                
                let result = try? executionContext["output"].get() as? [String]
                expect(result).to(contain("data\n"))
            }
            
            it("step 4: reroutes output to contents") {
                executionContext["output"] = .success(["one", "two", "three"])
                
                let reroute = RerouteEntity(
                    aliasMap: ["input": "output", "output": "contents"],
                    executionContext: executionContext
                )
                
                let result = reroute.process()
                expect(result).to(equal(.proceed))
                
                let contents = try? executionContext["contents"].get() as? [String]
                expect(contents).to(equal(["one", "two", "three"]))
            }
            
            it("step 5: prints ensure block confirmation") {
                let ensureBlock = Print(
                    aliasMap: ["input": "message"],
                    executionContext: executionContext
                )
                
                executionContext["message"] = .success("Concatenation complete! Output saved in: output.txt")
                
                let output = captureStdOut {
                    _ = ensureBlock.process()
                }
                
                expect(output).to(equal("Concatenation complete! Output saved in: output.txt"))
            }
        }
        
        describe("model_hension multi-tick integration") {
            var executionContext: StreamExecutionContext!
            
            beforeEach {
                executionContext = StreamExecutionContext()
            }
            
            it("processes multiple files and reroutes final contents") {
                // ✅ Setup test directory and files
                let dir = "/tmp/model-hension"
                try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
                try? "alpha".write(toFile: "\(dir)/a.txt", atomically: true, encoding: .utf8)
                try? "bravo".write(toFile: "\(dir)/b.txt", atomically: true, encoding: .utf8)
                try? "skip me".write(toFile: "\(dir)/output.txt", atomically: true, encoding: .utf8)
                
                executionContext["baseDir"] = .success(dir)
                
                // ✅ Entities
                let readFiles = ReadFiles(
                    aliasMap: [
                        "output": "filename",
                        "pathname": "pathname"
                    ],
                    executionContext: executionContext
                )
                
                let skipping = SkipFilter(
                    valuesToSkip: ["output.txt"],
                    stream: "filename",
                    executionContext: executionContext
                )
                
                let reroute = RerouteEntity(
                    aliasMap: ["input": "output", "output": "contents"],
                    executionContext: executionContext
                )
                
                // ✅ Init only those that require it
                readFiles.initialize()
                reroute.initialize()
                executionContext.ensure("contents", defaultValue: [] as [String])
                
                // ✅ Main comprehension loop
                fileLoop: while true {
                    switch readFiles.next() {
                    case .proceed:
                        switch skipping.include() {
                        case .proceed:
                            // ✅ Sub-hension gets its own context with just the pathname
                            let fileContext = StreamExecutionContext()
                            let pathname = try? executionContext["pathname"].get()
                            fileContext.ensure("filename", defaultValue: pathname ?? "~invalid~")
                            
                            // ✅ Run Comprehension_ProcessFile directly
                            let processFile = Comprehension_ProcessFile(executionContext: fileContext)
                            let result = processFile.execute()
                            expect(result).to(equal(.proceed))
                            // ✅ Synchronize output from sub-hension into parent context
                            let sync = Synchronize(
                                aliasMap: [
                                    "input": "output",
                                    "output": "contents"
                                ],
                                source: fileContext,
                                destination: executionContext,
                            )
                            
                            expect(sync.process()).to(equal(.proceed))
                            
                            executionContext.endTick()
                            
                        case .notAvailable:
                            executionContext.endTick()
                            continue fileLoop
                            
                        default:
                            fail("Unexpected result from skipping")
                        }
                        
                    case .eof:
                        break fileLoop
                        
                    default:
                        fail("Unexpected result from readFiles")
                        break fileLoop
                    }
                }
                
                // ✅ Final assertions
                if let contents = try? executionContext["contents"].get() as? [String] {
                    expect(contents).to(contain("alpha\n"))
                    expect(contents).to(contain("bravo\n"))
                    expect(contents).toNot(contain("skip me"))
                } else {
                    fail("Expected contents stream to be present with a valid [String]")
                }
            }
        }
        
        describe("Model Hension Blueprint Instantiation and Execution using ManualLintRunner") {
            var executionContext: StreamExecutionContext!
            var blueprint: Comprehension_1A5D27B3!
            var modelInstance: ComprehensionInstance!
            var runner: ManualLintRunner!
            let testDir = "/tmp/model-hension1"
            
            beforeEach {
                // Setup a fresh execution context for each test.
                executionContext = StreamExecutionContext()
                
                // Create the test directory and sample files.
                try? FileManager.default.createDirectory(atPath: testDir, withIntermediateDirectories: true)
                try? "alpha".write(toFile: "\(testDir)/a.txt", atomically: true, encoding: .utf8)
                try? "bravo".write(toFile: "\(testDir)/b.txt", atomically: true, encoding: .utf8)
                try? "skip me".write(toFile: "\(testDir)/output.txt", atomically: true, encoding: .utf8)
                
                // Instantiate the blueprint (Comprehension_1A5D27B3 is the blueprint).
                blueprint = Comprehension_1A5D27B3(executionContext: executionContext)
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
                    modelInstance = blueprint.instantiate(preinitialization_lint: { operation in
                        executionContext.ensure("baseDir",defaultValue: testDir)
                        return .firstRun
                    }, executionContext: executionContext)
                    
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
            var executionContext: StreamExecutionContext!
            var blueprint: Comprehension_1A5D27B3!
            var modelInstance: ComprehensionInstance!
            var operation: MultitaskingEngine.Operation!
            let testDir = "/tmp/model-hension"
            
            beforeEach {
                // Setup a fresh execution context for each test.
                executionContext = StreamExecutionContext()
                
                // Create the test directory and sample files.
                try? FileManager.default.createDirectory(atPath: testDir, withIntermediateDirectories: true)
                try? "alpha".write(toFile: "\(testDir)/a.txt", atomically: true, encoding: .utf8)
                try? "bravo".write(toFile: "\(testDir)/b.txt", atomically: true, encoding: .utf8)
                try? "skip me".write(toFile: "\(testDir)/output.txt", atomically: true, encoding: .utf8)
                
                // Instantiate the blueprint (Comprehension_1A5D27B3 is the blueprint).
                blueprint = Comprehension_1A5D27B3(executionContext: executionContext)
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
                    modelInstance = blueprint.instantiate(preinitialization_lint: { _ in
                        executionContext.ensure("baseDir",defaultValue:  testDir)
                        return .firstRun
                    }, executionContext: executionContext)
                    
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
            var executionContext: StreamExecutionContext!
            var blueprint: Comprehension_1A5D27B3!
            var modelInstance: ComprehensionInstance!
            var operation: MultitaskingEngine.Operation! // Fully qualified to avoid ambiguity.
            var operationManager: OperationManager!
            let testDir = "/tmp/model-hension-OM-test"
            
            beforeEach {
                operationManager = await setupTestEnvironment()
                
                // Create a fresh execution context for each test.
                executionContext = StreamExecutionContext()
                
                // Set up test directory and sample files.
                try? FileManager.default.createDirectory(atPath: testDir, withIntermediateDirectories: true)
                try? "alpha".write(toFile: "\(testDir)/a.txt", atomically: true, encoding: .utf8)
                try? "bravo".write(toFile: "\(testDir)/b.txt", atomically: true, encoding: .utf8)
                try? "skip me".write(toFile: "\(testDir)/output.txt", atomically: true, encoding: .utf8)
                
                // Instantiate the blueprint (Comprehension_1A5D27B3 is our blueprint).
                blueprint = Comprehension_1A5D27B3(executionContext: executionContext)
                
                // Instantiate a model hension instance from the blueprint,
                // providing a preinitialization lint that injects 'baseDir'.
                modelInstance = blueprint.instantiate(preinitialization_lint: { _ in
                    executionContext.ensure("baseDir",defaultValue: testDir)
                    return .firstRun
                }, executionContext: executionContext)
                
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
