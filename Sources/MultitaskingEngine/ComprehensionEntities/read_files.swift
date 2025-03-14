//
//  read_files.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 3/13/25.
//

import Foundation

final class ReadFiles {
    private let basePath: String
    private let executionContext: ThreadExecutionContext
    private var enumerator: FileManager.DirectoryEnumerator?

    init(basePath: String, executionContext: ThreadExecutionContext) {
        self.basePath = basePath
        self.executionContext = executionContext
    }

    func initialize() {
        enumerator = FileManager.default.enumerator(atPath: basePath)
    }

    func next() -> EntityResult {
        guard let file = enumerator?.nextObject() as? String else { return .eof }
        
        executionContext.setStream(setter: ("raw_filename", file))
        return .proceed
    }

    func finalize() {
        enumerator = nil
    }
}
