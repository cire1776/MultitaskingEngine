//
//  Comprehension_1A5D27B3.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 3/28/25.
//

import Foundation

final class Comprehension_1A5D27B3: LintProvider,  @unchecked Sendable {
    let executionContext: StreamExecutionContext
    
    var lints: LintArray = []
    
    private let readFiles: ReadFiles
    private let skipOutput: SkipFilter
    
    public var operationName: String {
        "Comprehension_1A5D27B3"
    }
    
    init(executionContext: StreamExecutionContext?=nil) {
        self.executionContext = executionContext ?? StreamExecutionContext()
        
        readFiles = ReadFiles(
            aliasMap: ["output": "filename"],
            executionContext: self.executionContext
        )
        
        skipOutput = SkipFilter(
            valuesToSkip: ["output.txt"],
            stream: "filename",
            executionContext: self.executionContext
        )

        self.lints = [
            { _ in self.initialize() ; return .running },
            { _ in self.run() },
            { _ in self.finalize() ; return .completed },
            { _ in self.finalize() ; return .completed },
        ]
    }
    
    public func instantiate(preinitialization_lint: Lint?=nil, executionContext: StreamExecutionContext?=nil) -> ComprehensionInstance {
        return ComprehensionInstance(blueprint: self,preinitializationLint: preinitialization_lint, executionContext: executionContext)
    }
//
//    @inline(__always)
//    private func pre_initialize_streams() {
//        print("preintialization stream")
//        // Inject compile-time constant baseDir into the execution context.
//        executionContext["baseDir"] = .success("/tmp/model-hension")
//    }
//    
    @inline(__always)
    private func initialize() {
        print("initialize")
        readFiles.initialize()
        skipOutput.initialize()
    }

    @inline(__always)
    private func finalize() {
        print("finalize")
        readFiles.finalize()
        skipOutput.finalize()
    }
    
    @inline(__always)
    func run() -> OperationState {
        print("run")
        executionContext.ensure("contents", defaultValue: [String]())
        
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
                    assert(executionContext.pendingEvent != nil)
                    return .unusualExecutionEvent(executionContext.pendingEvent!)
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
                    assert(executionContext.pendingEvent != nil)
                    return .unusualExecutionEvent(executionContext.pendingEvent!)
                }
                
                // ✅ Step 3: Sub-hension execution
                let fileContext = StreamExecutionContext()
                guard let pathname = try? executionContext["pathname"].get() else {
                    fileContext.triggerUnusualEvent(.exception("Pathname not provided"))
                    return .unusualExecutionEvent(executionContext.pendingEvent!)
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
                    executionContext.triggerUnusualEvent(fileContext.pendingEvent!)
                    return .unusualExecutionEvent(executionContext.pendingEvent!)
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
                    assert(executionContext.pendingEvent != nil)
                    return .unusualExecutionEvent(executionContext.pendingEvent!)
                }
            } while false
            
            executionContext.endTick()
        }
        
        readFiles.finalize()
        skipOutput.finalize()
        
        return .completed
    }
}
