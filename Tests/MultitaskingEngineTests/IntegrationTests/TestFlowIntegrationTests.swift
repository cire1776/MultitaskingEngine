//
//  TestFlowIntegrationTests.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 4/6/25.
//

import Quick
import Nimble
@testable import MultitaskingEngine
@testable import TestHelpers

final class TestFlowIntegrationTests: AsyncSpec {
    override class func spec() {
        describe("Comprehension_S_TestFlow") {
            func runTestFlow(input: Any, expected: String) async {
                let result = await runComprehension(
                    input: input,
                    blueprint: Comprehension_S_TestFlow.init
                ) { context in
                    return (
                        preinit: preinits(["input": input, "comma_delimited_line": "~nil~"])(context),
                        extract: { try? context["comma_delimited_line"].get() as? String }
                    )
                }
                expect(result).to(equal(expected))
            }

            context("when input is a single string") {
                it("emits and transforms multi-line input correctly") {
                    await runTestFlow(input: "hello world\nthis is a test", expected: "hello,world,this,is,a,test")
                }

                it("handles single line input") {
                    await runTestFlow(input: "quick brown fox", expected: "quick,brown,fox")
                }

                it("handles empty string") {
                    await runTestFlow(input: "", expected: "")
                }

                it("handles only newline characters") {
                    await runTestFlow(input: "\n\n\n", expected: "")
                }

                it("handles mixed whitespace and newlines") {
                    await runTestFlow(input: "foo \n bar\nbaz", expected: "foo,bar,baz")
                }
            }

            context("when input is an array of strings") {
                it("emits array correctly") {
                    await runTestFlow(input: ["alpha", "beta gamma", "delta"], expected: "alpha,beta,gamma,delta")
                }

                it("emits empty array as empty string") {
                    await runTestFlow(input: [], expected: "")
                }

                it("emits array with empty strings properly") {
                    await runTestFlow(input: ["", "a", "", "b"], expected: "a,b")
                }
            }
        }
    }
}
