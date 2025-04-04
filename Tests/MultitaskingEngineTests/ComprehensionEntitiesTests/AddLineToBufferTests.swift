//
//  AddLineToBufferTests.swift
//  MultitaskingEngineTests
//
//  Created by Eric Russell on 3/16/25.
//

import Quick
import Nimble
@testable import MultitaskingEngine

final class AddLineToBufferTests: AsyncSpec {
    override class func spec() {
        var executionContext: StreamExecutionContext!
        var addLineToBuffer: AddLineToBuffer!
        
        beforeEach {
            executionContext = StreamExecutionContext()
            addLineToBuffer = AddLineToBuffer(executionContext: executionContext)
        }
        
        describe("Initialization") {
            it("uses default aliases for input and output") {
                addLineToBuffer = AddLineToBuffer(executionContext: executionContext)
                
                expect(addLineToBuffer.inputStream).to(equal("input"))   // ✅ Default alias
                expect(addLineToBuffer.outputStream).to(equal("output")) // ✅ Default alias
            }
            
            it("allows setting custom input and output aliases") {
                let customAliases = ["input": "line", "output": "buffer"]
                addLineToBuffer = AddLineToBuffer(aliasMap: customAliases, executionContext: executionContext)
                
                expect(addLineToBuffer.inputStream).to(equal("line"))   // ✅ Custom input alias
                expect(addLineToBuffer.outputStream).to(equal("buffer")) // ✅ Custom output alias
            }
        }
        
        describe("Processing") {
            beforeEach {
                addLineToBuffer = AddLineToBuffer(executionContext: executionContext)
                addLineToBuffer.initialize()
            }
            
            context("when input contains a valid line") {
                beforeEach {
                    executionContext["input"] = .success("Hello, ULang!") // ✅ Set initial line
                }
                
                it("appends line to an empty buffer array") {
                    let result = addLineToBuffer.process()
                    
                    expect(result).to(equal(.proceed)) // ✅ Successfully added
                    expect(try? executionContext["output"].get() as? [String])
                        .to(equal(["Hello, ULang!"])) // ✅ First line added
                }
                
                it("appends multiple lines correctly") {
                    _ = addLineToBuffer.process() // ✅ First line
                    executionContext["input"] = .success("Second line")
                    let result = addLineToBuffer.process() // ✅ Second line
                    
                    expect(result).to(equal(.proceed))
                    expect(try? executionContext["output"].get() as? [String])
                        .to(equal(["Hello, ULang!", "Second line"])) // ✅ Correct appending
                }
            }
            
            context("when input is nil") {
                beforeEach {
                    executionContext["input"] = .success(nil) // ✅ Simulate missing input
                }
                
                it("triggers a warning and does not modify the buffer") {
                    _ = addLineToBuffer.process()
                   
                    expect(executionContext.pendingEvent).to(equal(.warning("Nil input received.")))
                    if case let .failure(error) = executionContext["output"] {
                        expect(error).to(matchError(ExecutionContextError.variableNotFound("output")))
                    }
                }
            }
        }
        
        context("when input is an empty string") {
            beforeEach {
                executionContext["input"] = .success("") // ✅ Empty string
            }
            
            it("appends an empty line to the buffer array") {
                let result = addLineToBuffer.process()
                
                expect(result).to(equal(.proceed))
                expect(try? executionContext["output"].get() as? [String])
                    .to(equal([""])) // ✅ Empty line is still added
            }
        }
        
        context("when buffer already contains data") {
            beforeEach {
                executionContext["output"] = .success(["Existing Buffer"])
                executionContext["input"] = .success("New Line")
            }
            
            it("appends the new line instead of overwriting") {
                let result = addLineToBuffer.process()
                
                expect(result).to(equal(.proceed))
                expect(try? executionContext["output"].get() as? [String])
                    .to(equal(["Existing Buffer", "New Line"])) // ✅ Proper accumulation
            }
        }
        
        context("when handling a large number of lines") {
            beforeEach {
                executionContext["output"] = .success([])
            }
            
            it("efficiently appends 10,000 lines without corruption") {
                let largeCount = 10_000
                for i in 1...largeCount {
                    executionContext["input"] = .success("Line \(i)")
                    _ = addLineToBuffer.process()
                }
                
                let resultBuffer = try? executionContext["output"].get() as? [String]
                expect(resultBuffer).toNot(beNil())
                
                let expectedLastLine = "Line \(largeCount)"
                expect(resultBuffer?.last).to(equal(expectedLastLine)) // ✅ Last line should be present
            }
        }
        
        context("ensuring input is unchanged") {
            beforeEach {
                executionContext["input"] = .success("Preserve Me")
            }
            
            it("does not modify the input stream") {
                let result = addLineToBuffer.process()
                
                expect(result).to(equal(.proceed))
                expect(try? executionContext["input"].get() as? String)
                    .to(equal("Preserve Me")) // ✅ Input is unchanged
            }
        }
    }
}

