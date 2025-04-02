//
//  read_files.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 3/13/25.
//

import Foundation

final class ReadFiles {
    private var basePath: String = "."
    let filenameStream: String
    let pathnameStream: String
    private let executionContext: StreamExecutionContext
    private var enumerator: FileManager.DirectoryEnumerator?

    init(aliasMap: [String: String]=[:], executionContext: StreamExecutionContext) {
        self.filenameStream = aliasMap["filename"] ?? "filename"
        self.pathnameStream = aliasMap["pathname"] ?? "pathname"
        self.executionContext = executionContext
    }

    func initialize() {
        self.basePath = (try? executionContext["baseDir"].get() as? String) ?? self.basePath
        enumerator = FileManager.default.enumerator(atPath: basePath)
    }

    func next() -> EntityResult {
        guard let file = enumerator?.nextObject() as? String else { return .eof }
        
        executionContext[filenameStream] = .success(file)
        executionContext[pathnameStream] = .success("\(self.basePath)/\(file)")
        return .proceed
    }

    func finalize() {
        enumerator = nil
    }
}
