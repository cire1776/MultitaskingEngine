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
            func createPreinitLint(value: Any?, executionContext: StreamExecutionContext) -> Lint {
                return { [executionContext] _ in
                    executionContext.ensure("input", defaultValue: value)
                    executionContext.ensure("comma_delimited_line", defaultValue: "~nil~")
                    return .running }
                
            }

            func runComprehension(input: Any) async -> String? {
                let context = SubscriptionStreamExecutionContext()
                let preinit = createPreinitLint(value: input, executionContext: context)

                let blueprint = Comprehension_S_TestFlow(executionContext: context)
                let instance = blueprint.instantiate(preinitialization_lint: preinit, executionContext: context)

                let runner = ManualLintRunner(provider: instance)
                _ = await runner.executeAll()

                return try? context["comma_delimited_line"].get() as? String
            }

            context("when input is a single string") {
                it("emits and transforms multi-line input correctly") {
                    let result = await runComprehension(input: "hello world\nthis is a test")
                    expect(result).to(equal("hello,world,this,is,a,test"))
                }

                it("handles single line input") {
                    let result = await runComprehension(input: "quick brown fox")
                    expect(result).to(equal("quick,brown,fox"))
                }

                it("handles empty string") {
                    let result = await runComprehension(input: "")
                    expect(result).to(equal(""))
                }

                it("handles only newline characters") {
                    let result = await runComprehension(input: "\n\n\n")
                    expect(result).to(equal(""))
                }

                it("handles mixed whitespace and newlines") {
                    let result = await runComprehension(input: "foo \n bar\nbaz")
                    expect(result).to(equal("foo,bar,baz"))
                }
            }

            context("when input is an array of strings") {
                it("emits array correctly") {
                    let result = await runComprehension(input: ["alpha", "beta gamma", "delta"])
                    expect(result).to(equal("alpha,beta,gamma,delta"))
                }

                it("emits empty array as empty string") {
                    let result = await runComprehension(input: [])
                    expect(result).to(equal(""))
                }

                it("emits array with empty strings properly") {
                    let result = await runComprehension(input: ["", "a", "", "b"])
                    expect(result).to(equal("a,b"))
                }
            }
        }
    }
}
