//
//  main.swift.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 4/19/25.
//

import Foundation

public struct ULangEntityID: Hashable, CustomStringConvertible, ExpressibleByStringLiteral, Sendable {
    public static let NULL = ULangEntityID("~NULL~")
    
    public let id: UInt64
    public let raw: String

    public init(_ id: UInt64) {
        self.id = id
        self.raw = "\(id)"
    }

    public init(_ string: String) {
        self.id = string.stableHash64
        self.raw = string
    }

    public init(stringLiteral value: StringLiteralType) {
        self.id = value.stableHash64
        self.raw = value
    }

    public var description: String {
        return "0x" + String(id, radix: 16).uppercased()
    }
}

public enum ULangEntityKind: Sendable {
    case compound
    case operation
    case keyword
    case binding
    case annotation
    case missing
    // extend as needed
}

public struct SourcePosition: Hashable, Sendable {
    public let line: Int
    public let column: Int

    public init(line: Int, column: Int) {
        self.line = line
        self.column = column
    }
}

public struct SourceRange: Hashable, Sendable {
    public let start: SourcePosition
    public let end: SourcePosition

    public init(start: SourcePosition, end: SourcePosition) {
        self.start = start
        self.end = end
    }
}

public struct ULangEntity: Hashable, Sendable {
    public static let NULL = ULangEntity(kind: .missing,
                                         sourceText: "Source Entity Missing",
                                         sourceContext: "Source Entity Missing",
                                         file: "unknown",
                                         range: SourceRange(start: SourcePosition(line: 0, column: 0), end: SourcePosition(line: 0, column: 0)))
    
    public let kind: ULangEntityKind
    public let sourceText: String       // just the operation text, like "emit character"
    public let sourceContext: String    // surrounding code with ANSI formatting
    public let file: String             // source file name (or comprehension name)
    public let range: SourceRange

    public init(
        kind: ULangEntityKind,
        sourceText: String,
        sourceContext: String,
        file: String,
        range: SourceRange,
    ) {
        self.kind = kind
        self.range = range
        self.sourceText = sourceText
        self.sourceContext = sourceContext
        self.file = file
    }
}
