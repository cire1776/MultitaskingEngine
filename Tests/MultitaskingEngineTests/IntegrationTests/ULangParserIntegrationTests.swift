//
//  ULangParserIntegrationTests.swift
//  MultitaskingEngineTests
//
//  Created by ULang Dev Team
//

import Quick
import Nimble
@testable import MultitaskingEngine
@testable import TestHelpers

final class ULangParserIntegrationTests: AsyncSpec {
    override class func spec() {
        describe("Comprehension_S_ULangParser") {
            func runParserComprehension(input: Any) async -> [Group]? {
                let result: [Group]? = await runComprehension(
                    input: input,
                    blueprint: Comprehension_S_ULangParser.init
                ) { context in
                    return (
                        preinit: preinits(["input": input, "ast": []])(context),
                        extract: { try? context["ast"].get() as? [Group] }
                    )
                }
                return result
            }
            
            context("the first test MUST be the parser itself!") {
                it("parses itself") {
                    let result = await runParserComprehension(input: "ULangParser = => subscription {\nfrom emit line ->\nemit character ->\nidentify_symbols ->\ncollect groups ->\ndetect delimiters ->\nconvert groups into tokens ->\nbuild ast.\n}")
                    expect(result).to(equal([
                        Group(kind: .bareword, value: "ULangParser"),
                        Group(kind: .whitespace, value: " "),
                        Group(kind: .symbol, value: "="),
                        Group(kind: .whitespace, value: " "),
                        Group(kind: .symbol, value: "="),
                        Group(kind: .symbol, value: ">"),
                        Group(kind: .whitespace, value: " "),
                        Group(kind: .bareword, value: "subscription"),
                        Group(kind: .whitespace, value: " "),
                        Group(kind: .symbol, value: "{"),
                        Group(kind: .whitespace, value: "\n"),

                        Group(kind: .bareword, value: "from"),
                        Group(kind: .whitespace, value: " "),
                        Group(kind: .bareword, value: "emit"),
                        Group(kind: .whitespace, value: " "),
                        Group(kind: .bareword, value: "line"),
                        Group(kind: .whitespace, value: " "),
                        Group(kind: .symbol, value: "-"),
                        Group(kind: .symbol, value: ">"),
                        Group(kind: .whitespace, value: "\n"),

                        Group(kind: .bareword, value: "emit"),
                        Group(kind: .whitespace, value: " "),
                        Group(kind: .bareword, value: "character"),
                        Group(kind: .whitespace, value: " "),
                        Group(kind: .symbol, value: "-"),
                        Group(kind: .symbol, value: ">"),
                        Group(kind: .whitespace, value: "\n"),

                        Group(kind: .bareword, value: "identify"),
                        Group(kind: .symbol, value: "_"),
                        Group(kind: .bareword, value: "symbols"),
                        Group(kind: .whitespace, value: " "),
                        Group(kind: .symbol, value: "-"),
                        Group(kind: .symbol, value: ">"),
                        Group(kind: .whitespace, value: "\n"),

                        Group(kind: .bareword, value: "collect"),
                        Group(kind: .whitespace, value: " "),
                        Group(kind: .bareword, value: "groups"),
                        Group(kind: .whitespace, value: " "),
                        Group(kind: .symbol, value: "-"),
                        Group(kind: .symbol, value: ">"),
                        Group(kind: .whitespace, value: "\n"),

                        Group(kind: .bareword, value: "detect"),
                        Group(kind: .whitespace, value: " "),
                        Group(kind: .bareword, value: "delimiters"),
                        Group(kind: .whitespace, value: " "),
                        Group(kind: .symbol, value: "-"),
                        Group(kind: .symbol, value: ">"),
                        Group(kind: .whitespace, value: "\n"),
                        Group(kind: .bareword, value: "convert"),
                        Group(kind: .whitespace, value: " "),
                        Group(kind: .bareword, value: "groups"),
                        Group(kind: .whitespace, value: " "),
                        Group(kind: .bareword, value: "into"),
                        Group(kind: .whitespace, value: " "),
                        Group(kind: .bareword, value: "tokens"),
                        Group(kind: .whitespace, value: " "),
                        Group(kind: .symbol, value: "-"),
                        Group(kind: .symbol, value: ">"),
                        Group(kind: .whitespace, value: "\n"),
                        Group(kind: .bareword, value: "build"),
                        Group(kind: .whitespace, value: " "),
                        Group(kind: .bareword, value: "ast"),
                        Group(kind: .symbol, value: "."),
                        Group(kind: .whitespace, value: "\n"),

                        Group(kind: .symbol, value: "}")
                    ]))
                }
            }
            
            context("basic parsing cases") {
                it("parses a single line with multiple words") {
                    let result = await runParserComprehension(input: "let x = 5")
                    expect(result).to(equal([
                        Group(kind: .bareword, value: "let"),
                        Group(kind: .whitespace, value: " "),
                        Group(kind: .bareword, value: "x"),
                        Group(kind: .whitespace, value: " "),
                        Group(kind: .symbol, value: "="),
                        Group(kind: .whitespace, value: " "),
                        Group(kind: .digits, value: "5")
                    ]))
                }

                it("parses multiple lines") {
                    let result = await runParserComprehension(input: "let x = 5\nprint x")
                    expect(result).to(equal([
                        Group(kind: .bareword, value: "let"),
                        Group(kind: .whitespace, value: " "),
                        Group(kind: .bareword, value: "x"),
                        Group(kind: .whitespace, value: " "),
                        Group(kind: .symbol, value: "="),
                        Group(kind: .whitespace, value: " "),
                        Group(kind: .digits, value: "5"),
                        Group(kind: .whitespace, value: "\n"),
                        Group(kind: .bareword, value: "print"),
                        Group(kind: .whitespace, value: " "),
                        Group(kind: .bareword, value: "x")
                    ]))
                }

                it("handles empty input string") {
                    let result = await runParserComprehension(input: "")
                    expect(result).to(equal([]))
                }

                it("handles newline-only input") {
                    let result = await runParserComprehension(input: "\n\n\n")
                    expect(result).to(equal([
                        Group(kind: .whitespace, value: "\n\n\n"),

                    ]))
                }

                it("ignores extra spaces") {
                    let result = await runParserComprehension(input: "  let    x   =   5  ")
                    expect(result).to(equal([
                        Group(kind: .whitespace, value: "  "),
                        Group(kind: .bareword, value: "let"),
                        Group(kind: .whitespace, value: "    "),
                        Group(kind: .bareword, value: "x"),
                        Group(kind: .whitespace, value: "   "),
                        Group(kind: .symbol, value: "="),
                        Group(kind: .whitespace, value: "   "),
                        Group(kind: .digits, value: "5"),
                        Group(kind: .whitespace, value: "  ")
                    ]))
                }
            }

            context("advanced parsing cases") {
                it("handles complex symbols") {
                    let result = await runParserComprehension(input: "x >= 10 && y != 5",)
                    expect(result).to(equal([
                        Group(kind: .bareword, value: "x"),
                        Group(kind: .whitespace, value: " "),
                        Group(kind: .symbol, value: ">"),
                        Group(kind: .symbol, value: "="),
                        Group(kind: .whitespace, value: " "),
                        Group(kind: .digits, value: "10"),
                        Group(kind: .whitespace, value: " "),
                        Group(kind: .symbol, value: "&"),
                        Group(kind: .symbol, value: "&"),
                        Group(kind: .whitespace, value: " "),
                        Group(kind: .bareword, value: "y"),
                        Group(kind: .whitespace, value: " "),
                        Group(kind: .symbol, value: "!"),
                        Group(kind: .symbol, value: "="),
                        Group(kind: .whitespace, value: " "),
                        Group(kind: .digits, value: "5")
                    ]))
                }

                it("parses ULang-style declarations") {
                    let result = await runParserComprehension(input: "define counter as 0")
                    expect(result).to(equal([
                        Group(kind: .bareword, value: "define"),
                        Group(kind: .whitespace, value: " "),
                        Group(kind: .bareword, value: "counter"),
                        Group(kind: .whitespace, value: " "),
                        Group(kind: .bareword, value: "as"),
                        Group(kind: .whitespace, value: " "),
                        Group(kind: .digits, value: "0")
                    ]))
                }

                it("handles Unicode identifiers") {
                    let result = await runParserComprehension(input: "变量 = 10")
                    expect(result).to(equal([
                        Group(kind: .bareword, value: "变量"),
                        Group(kind: .whitespace, value: " "),
                        Group(kind: .symbol, value: "="),
                        Group(kind: .whitespace, value: " "),
                        Group(kind: .digits, value: "10")
                    ]))
                }

                it("parses strings as single tokens") {
                    let result = await runParserComprehension(input: "print \"hello world\"")
                    expect(result).to(equal([
                        Group(kind: .bareword, value: "print"),
                        Group(kind: .whitespace, value: " "),
                        Group(kind: .symbol, value: "\""),
                        Group(kind: .bareword, value: "hello"),
                        Group(kind: .whitespace, value: " "),
                        Group(kind: .bareword, value: "world"),
                        Group(kind: .symbol, value: "\"")
                    ]))
                }

                it("handles array of line strings") {
                    let result = await runParserComprehension(input: ["let x = 1", "let y = 2"])
                    expect(result).to(equal([
                        Group(kind: .bareword, value: "let"),
                        Group(kind: .whitespace, value: " "),
                        Group(kind: .bareword, value: "x"),
                        Group(kind: .whitespace, value: " "),
                        Group(kind: .symbol, value: "="),
                        Group(kind: .whitespace, value: " "),
                        Group(kind: .digits, value: "1"),
                        Group(kind: .bareword, value: "let"),
                        Group(kind: .whitespace, value: " "),
                        Group(kind: .bareword, value: "y"),
                        Group(kind: .whitespace, value: " "),
                        Group(kind: .symbol, value: "="),
                        Group(kind: .whitespace, value: " "),
                        Group(kind: .digits, value: "2")
                    ]))
                }

                it("parses mixed input with comments") {
                    let result = await runParserComprehension(input: "let x = 5 // initialize\nprint x")
                    expect(result).to(equal([
                        Group(kind: .bareword, value: "let"),
                        Group(kind: .whitespace, value: " "),
                        Group(kind: .bareword, value: "x"),
                        Group(kind: .whitespace, value: " "),
                        Group(kind: .symbol, value: "="),
                        Group(kind: .whitespace, value: " "),
                        Group(kind: .digits, value: "5"),
                        Group(kind: .whitespace, value: " "),
                        Group(kind: .symbol, value: "/"),
                        Group(kind: .symbol, value: "/"),
                        Group(kind: .whitespace, value: " "),
                        Group(kind: .bareword, value: "initialize"),
                        Group(kind: .whitespace, value: "\n"),
                        Group(kind: .bareword, value: "print"),
                        Group(kind: .whitespace, value: " "),
                        Group(kind: .bareword, value: "x")
                    ]))
                }
            }
        }
    }
}
