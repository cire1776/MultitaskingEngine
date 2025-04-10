//
//  IdentifySymbols.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 4/8/25.
//

import Quick
import Nimble
@testable import MultitaskingEngine
@testable import TestHelpers

import MultitaskingEngine

func runEntityInPlaceAsGroup<E: IdentifySymbols>(
    entity: E.Type,
    input: [Character],
    stream: String = "input",
    executionContext: StreamExecutionContext = SubscriptionStreamExecutionContext()
) async -> [Any?] {

    let instance = entity.init(executionContext: executionContext)
    var groups = [Any?]()
    
    // Run until exhausted or not available
    for nextChar in input {
        // Preload the input stream with raw strings
        executionContext[stream] = .success(nextChar)

        let result = instance.process()

        switch result {
        case .eof, .notAvailable:
            groups.append(try? executionContext[stream].get())
        case .proceed:
            groups.append(try? executionContext[stream].get())
        default:
            continue
        }
    }

    // Extract rewritten values as [Group]
    return groups
}

final class IdentifySymbolsTests: AsyncSpec {
    override class func spec() {
        describe("CollectSymbols") {
            func runCollectSymbols(input: String) async -> [Any?] {
                await runEntityInPlaceAsGroup(entity: IdentifySymbols.self, input: input.map{$0} )
            }

            it("emits common single symbols") {
                let result = await runCollectSymbols(input: "+-*/=!")
                
                expect(result[0] as? Group).to(equal(Group(kind: .symbol, value: "+")))
                expect(result[1] as? Group).to(equal(Group(kind: .symbol, value: "-")))
                expect(result[2] as? Group).to(equal(Group(kind: .symbol, value: "*")))
                expect(result[3] as? Group).to(equal(Group(kind: .symbol, value: "/")))
                expect(result[4] as? Group).to(equal(Group(kind: .symbol, value: "=")))
                expect(result[5] as? Group).to(equal(Group(kind: .symbol, value: "!")))
            }

            it("ignores whitespace") {
                let result = await runCollectSymbols(input: " \t\n")
                expect(result.count).to(equal(3))
                expect(result[0] as? Character).to(equal(" "))
                expect(result[1] as? Character).to(equal("\t"))
                expect(result[2] as? Character).to(equal("\n"))
            }

            it("handles mixed input") {
                let result = await runCollectSymbols(input: "a+b=c")
                expect(result.count).to(equal(5))
                expect(result[0] as? Character).to(equal("a"))
                expect(result[1] as? Group).to(equal(Group(kind: .symbol, value: "+")))
                expect(result[2] as? Character).to(equal("b"))
                expect(result[3] as? Group).to(equal(Group(kind: .symbol, value: "=")))
                expect(result[4] as? Character).to(equal("c"))
            }

            it("captures brackets and punctuation") {
                let result = await runCollectSymbols(input: "[]{},.")
                expect(result.count).to(equal(6))
                expect(result[0] as? Group).to(equal(Group(kind: .symbol, value: "[")))
                expect(result[1] as? Group).to(equal(Group(kind: .symbol, value: "]")))
                expect(result[2] as? Group).to(equal(Group(kind: .symbol, value: "{")))
                expect(result[3] as? Group).to(equal(Group(kind: .symbol, value: "}")))
                expect(result[4] as? Group).to(equal(Group(kind: .symbol, value: ",")))
                expect(result[5] as? Group).to(equal(Group(kind: .symbol, value: ".")))
            }

            it("captures angle brackets and pipes") {
                let result = await runCollectSymbols(input: "<>|")
                expect(result.count).to(equal(3))
                expect(result[0] as? Group).to(equal(Group(kind: .symbol, value: "<")))
                expect(result[1] as? Group).to(equal(Group(kind: .symbol, value: ">")))
                expect(result[2] as? Group).to(equal(Group(kind: .symbol, value: "|")))
            }

            it("ignores emoji") {
                let result = await runCollectSymbols(input: "🔥🚀💡")
                expect(result.count).to(equal(3))
                expect(result[0] as? Character).to(equal("🔥"))
                expect(result[1] as? Character).to(equal("🚀"))
                expect(result[2] as? Character).to(equal("💡"))
            }

            it("captures exclamation and question marks") {
                let result = await runCollectSymbols(input: "!?")
                expect(result.count).to(equal(2))
                expect(result[0] as? Group).to(equal(Group(kind: .symbol, value: "!")))
                expect(result[1] as? Group).to(equal(Group(kind: .symbol, value: "?")))
            }

            it("captures tildes and carets") {
                let result = await runCollectSymbols(input: "~^")
                expect(result.count).to(equal(2))
                expect(result[0] as? Group).to(equal(Group(kind: .symbol, value: "~")))
                expect(result[1] as? Group).to(equal(Group(kind: .symbol, value: "^")))
            }

            it("handles quote characters") {
                let result = await runCollectSymbols(input: "\"'`")
                expect(result.count).to(equal(3))
                expect(result[0] as? Group).to(equal(Group(kind: .symbol, value: "\"")))
                expect(result[1] as? Group).to(equal(Group(kind: .symbol, value: "'")))
                expect(result[2] as? Group).to(equal(Group(kind: .symbol, value: "`")))
            }

            it("returns empty on empty input") {
                let result = await runCollectSymbols(input: "")
                expect(result).to(beEmpty())
            }
        }
    }
}
