//
//  PrintTests.swift
//  MultitaskingEngineTests
//
//  Created by Eric Russell on 3/21/25.
//

import Quick
import Nimble
@testable import MultitaskingEngine
@testable import TestHelpers

final class PrintTests: AsyncSpec {
    override class func spec() {
        var executionContext: StreamExecutionContext!
        var printEntity: Print!

        beforeEach {
            executionContext = StreamExecutionContext()
        }

        describe("Initialization") {
            it("uses the default alias 'input'") {
                printEntity = Print(executionContext: executionContext)
                expect(printEntity.inputStream).to(equal("input"))
            }

            it("allows custom alias for input stream") {
                printEntity = Print(aliasMap: ["input": "value"], executionContext: executionContext)
                expect(printEntity.inputStream).to(equal("value"))
            }
        }

        describe("Processing") {
            context("when a valid string is present") {
                beforeEach {
                    executionContext["input"] = .success("Hello, ULang!")
                    printEntity = Print(executionContext: executionContext)
                }

                it("prints the value to stdout") {
                    let output = captureStdOut {
                        _ = printEntity.process()
                    }
                    expect(output).to(equal("Hello, ULang!"))
                }

                it("returns .proceed") {
                    let result = printEntity.process()
                    expect(result).to(equal(.proceed))
                }
            }

            context("when input is nil") {
                beforeEach {
                    executionContext["input"] = .success(nil)
                    printEntity = Print(executionContext: executionContext)
                }

                it("prints 'nil'") {
                    let output = captureStdOut {
                        _ = printEntity.process()
                    }
                    expect(output).to(equal("~nil~"))
                }

                it("returns .proceed") {
                    let result = printEntity.process()
                    expect(result).to(equal(.proceed))
                }
            }

            context("when input is an empty string") {
                beforeEach {
                    executionContext["input"] = .success("")
                    printEntity = Print(executionContext: executionContext)
                }

                it("prints an empty line") {
                    let output = captureStdOut {
                        _ = printEntity.process()
                    }
                    expect(output).to(equal(""))
                }

                it("returns .proceed") {
                    let result = printEntity.process()
                    expect(result).to(equal(.proceed))
                }
            }

            context("ensuring input is not mutated") {
                beforeEach {
                    executionContext["input"] = .success("Preserve Me")
                    printEntity = Print(executionContext: executionContext)
                }

                it("does not modify the input stream") {
                    _ = printEntity.process()
                    let value = try? executionContext["input"].get() as? String
                    expect(value).to(equal("Preserve Me"))
                }
            }
        }
    }
}
