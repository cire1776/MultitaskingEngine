//
//  source_snippet_extractor.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 4/13/25.
//

import Foundation

struct SourceSnippetExtractor {
    static func closureBody(from file: StaticString, at line: UInt) -> String? {
        let path = String(describing: file)
        guard let contents = try? String(contentsOfFile: path) else { return nil }
        let lines = contents.components(separatedBy: .newlines)
        guard Int(line) - 1 < lines.count else { return nil }

        let sourceLine = lines[Int(line) - 1]

        if let range = sourceLine.range(of: #"\{[^\{]*?(?:\bin\b)?[^}]*\}"#, options: .regularExpression) {
            return String(sourceLine[range]).trimmingCharacters(in: .whitespaces)
        }

        // Still nothing? Try even simpler fallback:
        if let range = sourceLine.range(of: #"\{[^}]*\}"#, options: .regularExpression) {
            return String(sourceLine[range]).trimmingCharacters(in: .whitespaces)
        }

        return nil
    }
}
//"//\n//  Comprehension_S_ULangParser.swift\n//  MultitaskingEngine\n//\n//  Created by Eric Russell on 4/5/25.\n//\n\n/*\n ULangParser = => subscription {\n     from emit line ->\n     emit character ->\n     identify_symbols ->\n     collect groups ->\n     detect delimiters ->\n     convert groups into tokens ->\n     build ast.\n }\n */\n\nimport Foundation\n\nfinal public class Comprehension_S_ULangParser: Comprehension.Subscription {\n    public var context: SubscriptionStreamExecutionContext\n    public var executionContext: StreamExecutionContext\n\n    public var table: any LintTable.Steppable\n\n    public var operationID: Int = UUID().hashValue\n\n    public var mainLoopID: Int = 2\n    public var tickFlowID: Int = 1\n\n    public var pumpers: [Int] = []\n\n    private let emitLine: EmitStringWithReturns\n    private let emitCharacter: EmitCharacter\n    private let identifySymbol: IdentifySymbols\n    private let collect: Collect\n    private let build: BuildAST\n    private let debugStream: DebugStream\n\n    private lazy var tickFlowEnt"...    
// "/Users/ericrussell/Library/Mobile Documents/com~apple~CloudDocs/Development/ULang/MultitaskingEngine/Sources/MultitaskingEngine/Comprehensions/Comprehension_S_ULangParser.swift"
