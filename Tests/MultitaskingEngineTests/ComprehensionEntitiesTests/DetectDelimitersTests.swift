//
//  DetectDelimitersTests.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 4/8/25.
//

import Quick
import Nimble
@testable import MultitaskingEngine
@testable import TestHelpers

final class DetectDelimiterTests: AsyncSpec {
    override class func spec() {
        describe("DetectDelimiter") {
            func runDetectDelimiter(input: String) async -> [Group] {
                let groups = input.map { Group(kind: .symbol, value: String($0)) }
                return await runDetectDelimiter(input: groups)
            }
            
            func runDetectDelimiter(input: [Group]) async -> [Group] {
                let context = SubscriptionStreamExecutionContext()

                let detector = DetectDelimiter(executionContext: context,
                                               subscriptions: 0x4,
                                               publishes: 0x8)
                var groups: [Group] = []

                loop: for nextInput in input {
                    while true {
                        context["input"] = .success(nextInput)
                        let result = detector.process()
                        
                        switch result {
                        case .proceed:
                            if let value = try? context["input"].get() as? Group {
                                groups.append(value)
                            }
                            continue loop
                        case .pump(_):
                            if let value = try? context["input"].get() as? Group {
                                groups.append(value)
                            }
                            continue
                        case .eof:
                            return groups
                        case .notAvailable:
                            continue loop
                        default:
                            continue loop
                        }
                    }
                }
                
                return groups
            }

            it("restores a non-delimiter symbol to the stream") {
                let result = await runDetectDelimiter(input: [
                    Group(kind: .symbol, value: "="),
                    Group(kind: .bareword, value: "let"),

                ])
                expect(result).to(equal([
                    Group(kind: .symbol, value: "="),
                    Group(kind: .bareword, value: "let"),
                ]))
            }
            
            it("detects a single delimiter like double quote") {
                let result = await runDetectDelimiter(input: "\"")
                expect(result).to(equal([Group(kind: .delimiter, value: "\"")]))
            }

            it("detects block comment opener '/*' as a single delimiter group") {
                let result = await runDetectDelimiter(input: "/*")
                expect(result).to(equal([Group(kind: .delimiter, value: "/*")]))
            }

            it("emits bareword group when there is no delimiter") {
                let result = await runDetectDelimiter(input: [Group(kind: .bareword, value: "hello")])
                expect(result).to(equal([Group(kind: .bareword, value: "hello")]))
            }

            it("emits full stream with mixed delimiters and words") {
                let result = await runDetectDelimiter(input: [
                    Group(kind: .bareword, value: "say"),
                    Group(kind: .symbol, value: "("),
                    Group(kind: .symbol, value: "\""),
                    Group(kind: .bareword, value: "hello"),
                    Group(kind: .symbol, value: "\""),
                    Group(kind: .symbol, value: ")"),
                    Group(kind: .whitespace, value: " "),
                    Group(kind: .symbol, value: "/"),
                    Group(kind: .symbol, value: "*"),
                    Group(kind: .whitespace, value: " "),
                    Group(kind: .bareword, value: "comment"),
                    Group(kind: .whitespace, value: " "),
                    Group(kind: .symbol, value: "*"),
                    Group(kind: .symbol, value: "/")
                ])
                expect(result).to(equal([
                    Group(kind: .bareword, value: "say"),
                    Group(kind: .delimiter, value: "("),
                    Group(kind: .delimiter, value: "\""),
                    Group(kind: .bareword, value: "hello"),
                    Group(kind: .delimiter, value: "\""),
                    Group(kind: .delimiter, value: ")"),
                    Group(kind: .whitespace, value: " "),
                    Group(kind: .delimiter, value: "/*"),
                    Group(kind: .whitespace, value: " "),
                    Group(kind: .bareword, value: "comment"),
                    Group(kind: .whitespace, value: " "),
                    Group(kind: .delimiter, value: "*/")
                ]))
            }

            it("detects double tilde as rich text delimiter") {
                let result = await runDetectDelimiter(input: [
                    Group(kind: .symbol, value: "~"),
                    Group(kind: .symbol, value: "~"),
                    Group(kind: .bareword, value: "hello"),
                    Group(kind: .symbol, value: "~"),
                    Group(kind: .symbol, value: "~")
                ])
                expect(result).to(equal([
                    Group(kind: .delimiter, value: "~~"),
                    Group(kind: .bareword, value: "hello"),
                    Group(kind: .delimiter, value: "~~")
                ]))
            }

            it("detects custom block start delimiters like '<<doc'") {
                let result = await runDetectDelimiter(input: [
                    Group(kind: .symbol, value: "<"),
                    Group(kind: .symbol, value: "<"),
                    Group(kind: .bareword, value: "doc")
                ])
                expect(result).to(equal([
                    Group(kind: .delimiter, value: "<<"),
                    Group(kind: .bareword, value: "doc"),
                ]))
            }


            it("preserves whitespace between tokens and delimiters") {
                let result = await runDetectDelimiter(input: [
                    Group(kind: .bareword, value: "foo"),
                    Group(kind: .whitespace, value: "  "),
                    Group(kind: .symbol, value: "~"),
                    Group(kind: .symbol, value: "~"),
                    Group(kind: .bareword, value: "bar"),
                    Group(kind: .symbol, value: "~"),
                    Group(kind: .symbol, value: "~"),
                    Group(kind: .whitespace, value: "  "),
                    Group(kind: .bareword, value: "baz")
                ])
                expect(result).to(equal([
                    Group(kind: .bareword, value: "foo"),
                    Group(kind: .whitespace, value: "  "),
                    Group(kind: .delimiter, value: "~~"),
                    Group(kind: .bareword, value: "bar"),
                    Group(kind: .delimiter, value: "~~"),
                    Group(kind: .whitespace, value: "  "),
                    Group(kind: .bareword, value: "baz")
                ]))
            }

            it("handles input with only a known delimiter") {
                let result = await runDetectDelimiter(input: "*/")
                expect(result).to(equal([Group(kind: .delimiter, value: "*/")]))
            }

            it("handles adjacent delimiters correctly") {
                let result = await runDetectDelimiter(input: "\"\"")
                expect(result).to(equal([
                    Group(kind: .delimiter, value: "\""),
                    Group(kind: .delimiter, value: "\"")
                ]))
            }

            it("returns empty on empty input") {
                let result = await runDetectDelimiter(input: "")
                expect(result).to(beEmpty())
            }
        }
    }
}

