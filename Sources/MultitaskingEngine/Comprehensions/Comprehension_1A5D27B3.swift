//
//  Comprehension_1A5D27B3.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 3/28/25.
//
/*
 ULang Hension:

 => {
     ( baseDir ≈ "/tmp/myfolder" )
     from directory
     -> readFiles
     -> skip "output.txt"
     -> processEachFile
     -> sync "output" into "contents"
     -> message ≈ "Concatenation complete! Output saved in: output.txt".
 } -> store contents

 define flow processFile => {
     reading line from file
     -> terminate: line
     -> print: line
     -> add line to buffer: output.
 } catch error {
     handleFileError(error, filename)
 }
 */

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
}
