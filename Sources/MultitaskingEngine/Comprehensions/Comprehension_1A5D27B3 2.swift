//
//  Comprehension_1A5D27B3.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 3/28/25.
//

import Foundation

final class Comprehension_1A5D27B3_2 {
    let executionContext: StreamExecutionContext
    
    private let readFiles: ReadFiles
    private let skipOutput: SkipFilter
    private let printCompletion: Print
    
    init(executionContext: StreamExecutionContext) {
        self.executionContext = executionContext
        
        readFiles = ReadFiles(
            aliasMap: ["output": "filename", "pathname": "pathname"],
            executionContext: executionContext
        )
        
        skipOutput = SkipFilter(
            valuesToSkip: ["output.txt"],
            stream: "filename",
            executionContext: executionContext
        )
        
        printCompletion = Print(
            aliasMap: ["input": "message"],
            executionContext: executionContext
        )
    }
    
    func execute() -> EntityResult {
        readFiles.initialize()
        skipOutput.initialize()
        
        executionContext.ensure("contents", defaultValue: [String]())
        executionContext["message"] = .success("Concatenation complete! Output saved in: output.txt")
        
        mainLoop: while true {
            // ✅ Tick flow — one run per outer loop cycle
            tickFlow: repeat {
                // ✅ Step 1: Read next filename
                switch readFiles.next() {
                case .notAvailable:
                    break tickFlow  // short-circuit tick
                    
                case .eof:
                    break mainLoop
                    
                case .proceed:
                    break  // continue tick
                    
                case .unusualExecutionEvent:
                    return .unusualExecutionEvent
                }
                
                // ✅ Step 2: Apply skip filter
                switch skipOutput.include() {
                case .notAvailable:
                    break tickFlow  // short-circuit tick
                    
                case .eof:
                    break mainLoop
                    
                case .proceed:
                    break  // continue tick
                    
                case .unusualExecutionEvent:
                    return .unusualExecutionEvent
                }
                
                // ✅ Step 3: Sub-hension execution
                let fileContext = StreamExecutionContext()
                guard let pathname = try? executionContext["pathname"].get() else {
                    fileContext.triggerUnusualEvent(.exception("Pathname not provided"))
                    return .unusualExecutionEvent
                }
                
                fileContext["filename"] = .success(pathname)
                
                let processFile = Comprehension_ProcessFile(executionContext: fileContext)
                let result = processFile.execute()
                
                switch result {
                case .notAvailable:
                    break tickFlow  // short-circuit tick
                    
                case .eof:
                    break mainLoop
                    
                case .proceed:
                    break  // continue tick
                    
                case .unusualExecutionEvent:
                    return .unusualExecutionEvent
                }
                
                // ✅ Step 4: Synchronize results back
                let sync = Synchronize(
                    aliasMap: [
                        "input": "output",
                        "output": "contents"
                    ],
                    source: fileContext,
                    destination: executionContext,
                )
                
                switch sync.process() {
                case .notAvailable:
                    break tickFlow  // short-circuit tick
                    
                case .eof:
                    break mainLoop
                    
                case .proceed:
                    break  // continue tick
                    
                case .unusualExecutionEvent:
                    return .unusualExecutionEvent
                }
            } while false
            
            executionContext.endTick()
        }
        
        readFiles.finalize()
        skipOutput.finalize()
        
        return .proceed
    }
}
