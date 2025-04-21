//
//  source_entity_map.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 4/19/25.
//
import MultitaskingEngine

let file = "ULangParser.ulang"

let ULangEntityMap: [ULangEntityID: ULangEntity] = [
    ULangEntityID("Comprehension_S_ULangParser"): ULangEntity(
        kind: .compound,
        sourceText: #"""
        Comprehension_S_ULangParser = => subscription {
            from emit line -> emit character ->
            identify_symbols -> collect groups ->
            detect delimiters -> convert groups into tokens ->
            build ast.
        }
        """#,
        sourceContext: #"""
        Comprehension_S_ULangParser = => subscription {
            from emit line -> emit character ->
            identify_symbols -> collect groups ->
            detect delimiters -> convert groups into tokens ->
            build ast.
        }
        """#,
        file: file,
        range: .init(
            start: .init(line: 1, column: 1),
            end:   .init(line: 6, column: 2)
        )
    ),
    ULangEntityID("emit line"): .init(
        kind: .operation,
        sourceText: "emit line",
        sourceContext: "\(ANSI.gray)from -> \(ANSI.reset)\(ANSI.white)emit line\(ANSI.reset)\(ANSI.gray) -> emit character\(ANSI.reset)",
        file: file,
        range: .init(
            start: .init(line: 2, column: 10),
            end:   .init(line: 2, column: 19)
        )
    ),

    ULangEntityID("emit character"): .init(
        kind: .operation,
        sourceText: "emit character",
        sourceContext: "\(ANSI.gray)emit line -> \(ANSI.reset)\(ANSI.white)emit character\(ANSI.reset)\(ANSI.gray) -> identify symbols\(ANSI.reset)",
        file: file,
        range: .init(
            start: .init(line: 2, column: 23),
            end:   .init(line: 2, column: 37)
        )
    ),

    ULangEntityID("identify symbols"): .init(
        kind: .operation,
        sourceText: "identify symbols",
        sourceContext: "\(ANSI.gray)emit character -> \(ANSI.reset)\(ANSI.white)identify symbols\(ANSI.reset)\(ANSI.gray) -> collect groups\(ANSI.reset)",
        file: file,
        range: .init(
            start: .init(line: 3, column: 5),
            end:   .init(line: 3, column: 22)
        )
    ),

    ULangEntityID("collect groups"): .init(
        kind: .operation,
        sourceText: "collect groups",
        sourceContext: "\(ANSI.gray)identify symbols -> \(ANSI.reset)\(ANSI.white)collect groups\(ANSI.reset)\(ANSI.gray) -> detect delimiters\(ANSI.reset)",
        file: file,
        range: .init(
            start: .init(line: 3, column: 26),
            end:   .init(line: 3, column: 40)
        )
    ),

    ULangEntityID("detect delimiters"): .init(
        kind: .operation,
        sourceText: "detect delimiters",
        sourceContext: "\(ANSI.gray)collect groups -> \(ANSI.reset)\(ANSI.white)detect delimiters\(ANSI.reset)\(ANSI.gray) -> convert groups into tokens\(ANSI.reset)",
        file: file,
        range: .init(
            start: .init(line: 4, column: 5),
            end:   .init(line: 4, column: 23)
        )
    ),

    ULangEntityID("convert groups into tokens"): .init(
        kind: .operation,
        sourceText: "convert groups into tokens",
        sourceContext: "\(ANSI.gray)detect delimiters -> \(ANSI.reset)\(ANSI.white)convert groups into tokens\(ANSI.reset)\(ANSI.gray) -> build ast\(ANSI.reset)",
        file: file,
        range: .init(
            start: .init(line: 4, column: 27),
            end:   .init(line: 4, column: 56)
        )
    ),

    ULangEntityID("build ast"): .init(
        kind: .operation,
        sourceText: "build ast",
        sourceContext: "\(ANSI.gray)convert groups into tokens -> \(ANSI.reset)\(ANSI.white)build ast\(ANSI.reset)",
        file: file,
        range: .init(
            start: .init(line: 5, column: 5),
            end:   .init(line: 5, column: 14)
        )
    ),
    
    ULangEntityID("debug stream"): .init(
        kind: .operation,
        sourceText: "debug stream",
        sourceContext: "\(ANSI.gray) -> \(ANSI.reset)\(ANSI.white)debug stream\(ANSI.reset)",
        file: file,
        range: .init(
            start: .init(line: 5, column: 5),
            end:   .init(line: 5, column: 14)
        )
    ),
]
