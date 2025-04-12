//
//  CollectTests.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 4/7/25.
//

import Quick
import Nimble
@testable import MultitaskingEngine
@testable import TestHelpers

final class CollectTests: AsyncSpec {
    override class func spec() {
        describe("Collect") {
            func runCollectEntity(input: String) async -> [Group] {
                let context = StreamExecutionContext()
                var groups: [Group] = []
                
                // Set up an empty output buffer
//                context["output"] = .success([Group]())
                context.ensure("output", defaultValue: "~nil~")
                let collect = Collect(
                    executionContext: context,
                    subscriptions: 0x4,
                    publishes: 0x8
                )

                for char in input {
                    // Simulate character-by-character streaming
                    context["input"] = .success(char)
                    let result = collect.process()
                    if result == .notAvailable { continue }
                    if let group = (try? context["output"].get() as? Group) {
                        groups.append(group)
                    }
                    context.endTick()
                }

                // Optionally drain any final buffer
                _ = collect.drain()
                if let group = (try? context["output"].get() as? Group) {
                    groups.append(group)
                }

                return groups
            }

            it("collects a bareword") {
                let result = await runCollectEntity(input: "hello")
                expect(result).to(equal([Group(kind: .bareword, value: "hello")]))
            }

            it("collects digits") {
                let result = await runCollectEntity(input: "123")
                expect(result).to(equal([Group(kind: .digits, value: "123")]))
            }

            it("groups whitespace") {
                let result = await runCollectEntity(input: "   \t\n")
                expect(result).to(equal([Group(kind: .whitespace, value: "   \t\n")]))
            }

            it("splits mixed types correctly") {
                let result = await runCollectEntity(input: "foo123 bar!")
                expect(result).to(equal([
                    Group(kind: .bareword, value: "foo"),
                    Group(kind: .digits, value: "123"),
                    Group(kind: .whitespace, value: " "),
                    Group(kind: .bareword, value: "bar"),
                    Group(kind: .symbol, value: "!")
                ]))
            }

            it("treats underscore as symbol") {
                let result = await runCollectEntity(input: "a_b")
                expect(result).to(equal([
                    Group(kind: .bareword, value: "a"),
                    Group(kind: .symbol, value: "_"),
                    Group(kind: .bareword, value: "b")
                ]))
            }

            it("treats emoji as symbol") {
                let result = await runCollectEntity(input: "x🔥y")
                expect(result).to(equal([
                    Group(kind: .bareword, value: "x🔥y")
                ]))
            }

            it("emits single characters correctly") {
                let result = await runCollectEntity(input: "a1 ")
                expect(result).to(equal([
                    Group(kind: .bareword, value: "a"),
                    Group(kind: .digits, value: "1"),
                    Group(kind: .whitespace, value: " ")
                ]))
            }

            it("returns empty on empty input") {
                let result = await runCollectEntity(input: "")
                expect(result).to(beEmpty())
            }

            it("handles always emits multiple symbols singly in sequence") {
                let result = await runCollectEntity(input: ">>=")
                expect(result).to(equal([
                    Group(kind: .symbol, value: ">>="),
                ]))
            }

            it("splits lines with multiple transitions") {
                let result = await runCollectEntity(input: "abc 123! xyz")
                expect(result).to(equal([
                    Group(kind: .bareword, value: "abc"),
                    Group(kind: .whitespace, value: " "),
                    Group(kind: .digits, value: "123"),
                    Group(kind: .symbol, value: "!"),
                    Group(kind: .whitespace, value: " "),
                    Group(kind: .bareword, value: "xyz")
                ]))
            }
        }
    }
}
