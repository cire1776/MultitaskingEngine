//
//  hension_operation_executable.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 3/7/25.
//
/*
 ULang Hension:
 
 => { read filename from "." as filename
 -> skip: "output.txt"
 -> processFile in order.
 } -> store output in "output.txt".
 
 define flow processFile => {
 reading line from file
 -> terminate: line
 -> print: line
 -> add line to buffer: output.
 } catch error {
 handleFileError(error, filename)
 } else {
 print "Concatenation complete! Output saved in: output.txt"
 }
 */

import Foundation
@testable import MultitaskingEngine

//final class HensionOperationExecutable: BaseOperationExecutable, @unchecked Sendable {
//    
//    private let executionContext: StreamExecutionContext
//    private let basePath: String  // ✅ Stores the absolute working directory
//    
//    init(operationName: String, executionContext: StreamExecutionContext, relativePath: String = ".") {
//        self.executionContext = executionContext
//        self.basePath = relativePath
//        super.init(operationName: operationName)
//    }
//    
//    final class ReadFile {
//        private let basePath: String
//        private let executionContext: StreamExecutionContext
//        private let enumerator: FileManager.DirectoryEnumerator?
//        
//        init(basePath: String, executionContext: StreamExecutionContext) {
//            let userPWD = ProcessInfo.processInfo.environment["PWD"] ?? FileManager.default.currentDirectoryPath
//            let resolvedPath = URL(fileURLWithPath: basePath).standardized.path
//            self.basePath = resolvedPath.hasPrefix("/") ? resolvedPath :
//            URL(fileURLWithPath: userPWD).appendingPathComponent(resolvedPath).standardized.path
//            
//            self.executionContext = executionContext
//            self.enumerator = FileManager.default.enumerator(atPath: self.basePath)
//        }
//        
//        func next() -> EntityResult {
//            guard let directory = enumerator?.nextObject() as? String else {
//                return .eof
//            }
//            executionContext["raw_filename"] = .success(directory)
//            return .proceed
//        }
//    }
//    
//    final class SkipFilter {
//        private let executionContext: StreamExecutionContext
//        private let stream: String
//        private let valuesToSkip: Set<String>
//
//        init(valuesToSkip: [String], stream: String, executionContext: StreamExecutionContext) {
//            self.stream = stream
//            self.valuesToSkip = Set(valuesToSkip)
//            self.executionContext = executionContext
//        }
//
//        func include() -> EntityResult {
//            guard case let .success(rawValue?) = executionContext[stream],
//                  let value = rawValue as? String else {
//                executionContext.triggerUnusualEvent( .exception("\(stream) missing or invalid"))
//                return .notAvailable
//            }
//
//            if valuesToSkip.contains(value) {
//                print("⏩ Skipping value: \(value)")
//                return .notAvailable
//            }
//
//            print("✅ Passed filter: \(value)")
//            return .proceed
//        }
//    }
//    
//    private func processFile() {
//        guard case let .success(filename) = executionContext["filename"], let filenameStr = filename as? String else {
//            executionContext.triggerUnusualEvent(.exception("Execution context does not contain a valid filename"))
//            return
//        }
//        
//        guard let fileHandle = FileHandle(forReadingAtPath: filenameStr) else {
//            executionContext.triggerUnusualEvent(.exception("Failed to open file: \(filenameStr)"))
//            return
//        }
//        defer { fileHandle.closeFile() }
//        
//        var outputBuffer: [String] = []
//        
//        while true {
//            let lineData = fileHandle.readData(ofLength: 1024)
//            if lineData.isEmpty { break }  // ✅ Exit loop on EOF
//            
//            if let line = String(data: lineData, encoding: .utf8) {
//                let processedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
//                print("📜 Read line: \(processedLine)")
//                outputBuffer.append(processedLine)
//            }
//        }
//        
//        executionContext["output"] = .success(outputBuffer)  // ✅ Keep the output inside EC
//    }
//}
//
////public func read_line(from: )
