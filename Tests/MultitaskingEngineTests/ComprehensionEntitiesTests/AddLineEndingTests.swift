//
//  AddLineEndingTests.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 3/16/25.
//

import Quick
import Nimble
@testable import MultitaskingEngine

final class AddLineEndingTests: AsyncSpec {

    // MARK - Entity Tests
    override class func spec() {
        var executionContext: StreamExecutionContext!
        var addLineEnding: AddLineEnding!
        
        beforeEach {
            executionContext = StreamExecutionContext()
            addLineEnding = AddLineEnding(aliasMap: ["input": "text"], executionContext: executionContext)
        }
        
        describe("Initialization") {
            it("allows setting a custom input alias") {
                let addLineEnding = AddLineEnding(aliasMap: ["input": "text"], executionContext: executionContext)
                expect(addLineEnding.inputStream).to(equal("text"))
            }
        }
        
        describe("Processing") {
            context("when input line is available") {
                beforeEach {
                    executionContext["text"] = .success("Hello, World") // ✅ Using custom alias
                }
                
                it("appends a newline character and stores it in the same stream") {
                    let result = addLineEnding.process()
                    
                    expect(result).to(equal(.proceed))
                    expect(try? executionContext["text"].get() as? String)
                        .to(equal("Hello, World\n")) // ✅ Stored in the same stream
                }
            }
        }
        
        describe("Processing") {
            context("when input line is available") {
                beforeEach {
                    executionContext["text"] = .success("Hello, World") // ✅ Using custom alias
                }
                
                it("appends a newline character and stores it in the same stream") {
                    let result = addLineEnding.process()
                    
                    expect(result).to(equal(.proceed))
                    expect(try? executionContext["text"].get() as? String)
                        .to(equal("Hello, World\n")) // ✅ Stored in the same stream
                }
            }
            
            context("when input line already ends in a newline") {
                beforeEach {
                    executionContext["text"] = .success("Hello, World\n")
                }

                it("does not modify the input") {
                    let result = addLineEnding.process()

                    expect(result).to(equal(.proceed))
                    expect(try? executionContext["text"].get() as? String)
                        .to(equal("Hello, World\n")) // ✅ No extra newline added
                }
            }
        }
    }
}
