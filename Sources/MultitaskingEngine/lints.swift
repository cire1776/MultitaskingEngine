//
//  lints.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 4/1/25.
//
import Foundation

public typealias Lint = (LintRunner) async -> OperationState
public typealias LintArray = [Lint]

#if DEBUG
public struct LintMetadata {
    static nonisolated(unsafe) public let NULL = LintMetadata()
    public var role: String
    public var file: StaticString?
    public var line: UInt?
    public var column: UInt?
    public var description: StaticString?
    public var sourceSnippet: String?
    
    public var uLangEntityID: ULangEntityID
    
    public let isNull: Bool

    public var shortFilePath: String? {
        guard let fullPath = self.file else { return nil }

        let url = URL(fileURLWithPath: String(describing: fullPath))
        let filename = url.lastPathComponent
        let folder = url.deletingLastPathComponent().lastPathComponent

        return "\(folder)/\(filename)"
    }
   
    public init() {
        self.role = "NONE"
        self.uLangEntityID = ULangEntityID("null")
        self.isNull = true
    }

    public init(metadata: LintMetadata, uLangEntityID: ULangEntityID) {
        self.role = metadata.role
        self.uLangEntityID = uLangEntityID
        self.file = metadata.file
        self.line = metadata.line
        self.column = metadata.column
        self.description = metadata.description
        self.isNull = metadata.isNull
    }
    
    public init(role: String,
                uLangEntityID: ULangEntityID,
                file: StaticString?=nil,
                line: UInt?=nil,
                column: UInt?=nil,
                description: StaticString? = "nil") {
        self.role = role
        self.uLangEntityID = uLangEntityID
        self.file = file
        self.line = line
        self.column = column
        self.description = description
        self.isNull = false
        
        if let file = file,
           let line = line,
           let column = column {
            self.sourceSnippet = SourceSnippetExtractor.closureBody(from: file, at: line)
        }
    }
}
#endif

public struct LintSpecifier {
    static nonisolated(unsafe) public let NULL = LintSpecifier({ _ in .unusualExecutionEvent(.exception("Not expected to be executed.")) }, role: "NULL", uLangEntityID: "~NULL~")
    
    public let lint: Lint
    public let metadata: LintMetadata
   
    public init(
        _ lint: @escaping Lint,
        role: String = "unspecified lint",
        uLangEntityID: ULangEntityID,
        file: StaticString = #filePath,
        line: UInt = #line,
        column: UInt = #column
    ) {
        self.lint = lint
    
#if DEBUG
        self.metadata = LintMetadata(
            role: role,
            uLangEntityID: uLangEntityID,
            file: file,
            line: line,
            column: column,
        )
#else
        self.metadata = .NULL
#endif
    }
    
    public init(
        _ lint: @escaping Lint,
        role: String = "unspecified lint",
        file: StaticString = #filePath,
        line: UInt = #line,
        column: UInt = #column
    ) {
        self.lint = lint
    
#if DEBUG
        self.metadata = LintMetadata(
            role: role,
            uLangEntityID: .NULL,
            file: file,
            line: line,
            column: column,
        )
#else
        self.metadata = .NULL
#endif
    }
    
    public init(
        _ lint: @escaping Lint,
        metadata: LintMetadata,
        ulangeEntityID: ULangEntityID
    ) {
        self.lint = lint
    
        #if DEBUG
        self.metadata = LintMetadata(metadata: metadata, uLangEntityID: ulangeEntityID
        )
    #else
        self.metadata = .NULL
    #endif
    }
    
    public func withULangEntityID(_ uLangEntityID: ULangEntityID) -> LintSpecifier {
        guard self.metadata.isNull == false else {
            fatalError("NULL metadata not allowed for LintSpecifier")
        }
        let newMetadata: LintMetadata
        
        if self.metadata.uLangEntityID == uLangEntityID {
            newMetadata = LintMetadata(metadata: self.metadata, uLangEntityID: uLangEntityID)
        } else {
            newMetadata = self.metadata
        }
        
        let copy = LintSpecifier(
            lint,
            metadata: newMetadata,
            ulangeEntityID: uLangEntityID
        )
        return copy
    }
}

