//
//  CollectStringsTests.swift
//  MultitaskingEngineTests
//
//  Created by ULang Dev Team, 4-10-25
//

import Quick
import Nimble
@testable import MultitaskingEngine
@testable import TestHelpers

final class CollectStringsTests: AsyncSpec {
    override class func spec() {
        describe("CollectStrings") {
            func runCollectStrings(input: [Any]) async -> [String] {
                await runCollectEntity(
                    input: input,
                    outputStream: "output",
                    using: { CollectStrings(executionContext: $0,
                                            subscriptions: 0x4,
                                            publishes: 0x8) },
                    execute: { $0.process() },
                    drain: { $0.drain() }
                )
            }

            it("collects a single string") {
                let result = await runCollectStrings(input: ["hello"])
                expect(result).to(equal(["hello"]))
            }

            it("accumulates multiple strings over time") {
                let result = await runCollectStrings(input: ["hello", " ", "world"])
                expect(result).to(equal(["hello", " ", "world"]))
            }

            it("accumulates single characters") {
                let result = await runCollectStrings(input: ["h", "e", "l", "l", "o"])
                expect(result).to(equal(["h","e","l","l","o"]))
            }

            it("handles mixed String and Character input") {
                let result = await runCollectStrings(input: ["a", Character("b"), "c", Character("!"), "d"])
                expect(result).to(equal(["a","b","c","!","d"]))
            }

            it("resets after returning a result") {
                let result = await runCollectStrings(input: ["a", "b", " ", "c", "d"])
                expect(result).to(equal(["a","b"," ","c","d"]))
            }

            it("handles empty input") {
                let result = await runCollectStrings(input: [])
                expect(result).to(equal([]))
            }

            it("joins newlines correctly") {
                let result = await runCollectStrings(input: ["line1", "\n", "line2"])
                expect(result).to(equal(["line1","\n","line2"]))
            }

            it("handles emoji characters") {
                let result = await runCollectStrings(input: ["This", " ", "is", " ", Character("🔥")])
                expect(result).to(equal(["This"," ","is"," ", "🔥"]))
            }

            it("collects multi-grapheme characters") {
                let result = await runCollectStrings(input: [Character("👨‍💻"), " is coding"])
                expect(result).to(equal(["👨‍💻", " is coding"]))
            }
        }
    }
}
