//
//  read_line_from_file.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 3/15/25.
//

import Foundation

// MARK: - Data Source: Read Line from File
class ReadLineFromFile: Comprehension.Entity {
    let inputStream: String
    let outputStream: String
    
    private(set) var filename: String!
    
    private var fileHandle: FileHandle?
    private var iterator: IndexingIterator<[String]>?
    private var executionContext: StreamExecutionContext
    private var hasInitialized = false
    private var buffer = Data()

    init(aliasMap: [String: String] = [:], executionContext: StreamExecutionContext) {
        self.inputStream = aliasMap["input"] ?? "input"
        self.outputStream = aliasMap["output"] ?? "output"
        
        self.executionContext = executionContext
    }

    func initialize() {
        let filename = try? executionContext[inputStream].get() as? String
        // ✅ Ensure filename exists in execution context
        guard let filename = filename else {
            executionContext.triggerUnusualEvent(.exception("Filename is required in Execution Context."))
            return
        }
        self.filename = filename
   }
    
    
    func next() -> EntityResult {
        // ✅ Lazy initialization of fileHandle (first call to `next()`)
        if !hasInitialized {
            hasInitialized = true
            do {
                fileHandle = try FileHandle(forReadingFrom: URL(fileURLWithPath: filename))
            } catch {
                executionContext.triggerUnusualEvent(.exception("File could not be opened: \(error)"))
                return .unusualExecutionEvent
            }
        }

        guard let fileHandle = fileHandle else {
            return .eof  // ✅ If fileHandle wasn't initialized, return EOF
        }

        // ✅ Check for a line in the buffer **before reading more data**
        while true {
            if let lineRange = buffer.range(of: Data("\n".utf8)) {
                let lineData = buffer.subdata(in: 0..<lineRange.lowerBound)
                let nextIndex = lineRange.upperBound  // ✅ Ensure we remove only the newline
                
                buffer.removeSubrange(0..<nextIndex)  // ✅ Correctly remove up to but not beyond
                
                if let lineString = String(data: lineData, encoding: .utf8) {
                    executionContext[outputStream] = .success(lineString)
                    return .proceed
                } else {
                    executionContext.triggerUnusualEvent( .exception("Failed to decode line from file."))
                }
            }

            // ✅ If no full line exists, **attempt to read more data**
            let chunk = fileHandle.readData(ofLength: 1024)
            if chunk.isEmpty {
                // ✅ Only return EOF **if buffer is also empty** (handles partial last lines)
                if buffer.isEmpty {
                    return .eof
                } else {
                    // ✅ Handle the last line without a trailing newline
                    let lastLine = String(data: buffer, encoding: .utf8) ?? ""
                    buffer.removeAll()
                    executionContext[outputStream] = .success(lastLine)
                    return .proceed
                }
            }

            buffer.append(chunk)  // ✅ Append new data to buffer
        }
    }

    func finalize() {
        fileHandle?.closeFile()  // ✅ Always close file on finalize()
        fileHandle = nil
    }
}
