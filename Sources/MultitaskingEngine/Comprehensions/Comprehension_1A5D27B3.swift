//
//  Comprehension_1A5D27B3.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 3/28/25.
//

import Foundation

final class Comprehension_1A5D27B3: Comprehension.Standard, LintProvider,  @unchecked Sendable {
    let executionContext: StreamExecutionContext
    
    var table: LintTable.Steppable
    
    private let readFiles: ReadFiles
    private let skipOutput: SkipFilter
    
    public var operationID: Int
    public var operationName: String {
        "Comprehension_\(String(format: "%X", operationID))"
    }
    
    init(executionContext: StreamExecutionContext?=nil) {
        self.executionContext = executionContext ?? StreamExecutionContext()
        self.operationID = Int("1A5D27B3", radix: 16)!
        readFiles = ReadFiles(
            aliasMap: ["output": "filename"],
            executionContext: self.executionContext
        )
        
        skipOutput = SkipFilter(
            valuesToSkip: ["output.txt"],
            stream: "filename",
            executionContext: self.executionContext
        )

        self.table = LintTable.Sequential(lints:[])
        
        self.table = LintTable.Sequential(lints:[
            { _ in self.initialize() ; return .running },
            { [self] in $0.pushSuboperation(table: LintTable.Sequential(lints: produceRun())); return .skipYield },
            { _ in self.finalize() ; return .completed },
            { _ in self.finalize() ; return .completed },
        ])
    }
    
    public func instantiate(preinitialization_lint: Lint?=nil, executionContext: StreamExecutionContext?=nil) -> Comprehension.Instance {
        return Comprehension.Instance(blueprint: self,preinitializationLint: preinitialization_lint, executionContext: executionContext)
    }
    
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
    private func produceTickFlow () -> LintTable.Steppable {
        let fileContext = StreamExecutionContext()
        
        return LintTable.Sequential(lints: [
            { [self] _ in
                switch readFiles.next() {
                case .notAvailable:
                    return .localBreak  // short-circuit tick
                case .eof:
                    return .nonLocalBreak(2)
                case .proceed:
                    break  // continue tick
                case .unusualExecutionEvent:
                    assert(executionContext.pendingEvent != nil)
                    return .unusualExecutionEvent(executionContext.pendingEvent!)
                }
                
                return .running
            },
            { [self] _ in
                switch skipOutput.include() {
                case .notAvailable:
                    return .localBreak  // short-circuit tick
                    
                case .eof:
                    return .nonLocalBreak(2)
                    
                case .proceed:
                    break  // continue tick
                    
                case .unusualExecutionEvent:
                    assert(executionContext.pendingEvent != nil)
                    return .unusualExecutionEvent(executionContext.pendingEvent!)
                }
                
                return .running
            },
            { [self] _ in
                guard let pathname = try? executionContext["pathname"].get() else {
                    fileContext.triggerUnusualEvent(.exception("Pathname not provided"))
                    return .unusualExecutionEvent(executionContext.pendingEvent!)
                }
                
                fileContext["filename"] = .success(pathname)
                
                let processFile = Comprehension_ProcessFile(executionContext: fileContext)
                let result = processFile.execute()
                
//                print(fileContext.dumpStreams())
//                print("result: ", result)
                
                switch result {
                case .notAvailable:
                    return .localBreak  // short-circuit tick
                    
                case .eof:
                    return .nonLocalBreak(2)
                    
                case .proceed:
                    break  // continue tick
                    
                case .unusualExecutionEvent:
                    executionContext.triggerUnusualEvent(fileContext.pendingEvent!)
                    return .unusualExecutionEvent(executionContext.pendingEvent!)
                }
                return .running
            },
            { [self] _ in
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
                    return .localBreak  // short-circuit tick
                    
                case .eof:
                    return .nonLocalBreak(2)
                    
                case .proceed:
                    break  // continue tick
                    
                case .unusualExecutionEvent:
                    assert(executionContext.pendingEvent != nil)
                    return .unusualExecutionEvent(executionContext.pendingEvent!)
                }
                
                return .localBreak
            },
        ])
    }
    
    @inline(__always)
    private func produceMainLoop () -> LintTable.Steppable {
        return LintTable.Loop(lints: [
            { [self] in $0.pushSuboperation(table: produceTickFlow()); return .skipYield },
//            { _ in print("Looping..."); return .running },
            { [self] _ in executionContext.endTick(); return .completed }, // continue to loop
        ], identifier: 2)
    }
    
    @inline(__always)
    private func produceRun () -> LintArray {
        return [
            { _ in print("run"); return .running },
            { [self] _ in executionContext.ensure("contents", defaultValue: [String]()); return .running },
            
            { [self] in $0.pushSuboperation(table: produceMainLoop()); return .skipYield  },
            
            { [self] _ in readFiles.finalize(); return .running },
            { [self] _ in skipOutput.finalize(); return .completed },
        ]
    }
    
    
    @inline(__always)
    func runx() -> OperationState {
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
