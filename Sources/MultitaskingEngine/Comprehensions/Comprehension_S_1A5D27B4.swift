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


final public class Comprehension_S_1A5D27B4: Comprehension.Subscription, @unchecked Sendable {
    public let executionContext: StreamExecutionContext
    public var table: LintTable.Steppable
    
    public var operationID: Int
    
    public let readFiles: ReadFiles
    public let skipOutput: SkipFilter
    
    public let fileContext = StreamExecutionContext()
    
    public var subscriptions = Subscriptions()
    
    init(executionContext: StreamExecutionContext?=nil) {
        guard executionContext == nil || executionContext is SubscriptionStreamExecutionContext else {
            fatalError("Expected a SubscriptionStreamExecutionContext!")
        }
        
        self.executionContext = executionContext ?? SubscriptionStreamExecutionContext(
            streamFlags: [
                "filename": 0x1,
                "pathname": 0x2,
                "output":   0x4,
                "contents": 0x8,
            ]
        )
        
        operationID = Int("1A5D27B4", radix: 16)!
        
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
            { [/*unowned*/ self] in $0.pushSuboperation(table: produceMainLoop()); return .skipYield },
            { _ in print("Concatenation complete! Output saved in: output.txt" ); return .running },
            { _ in self.finalize() ; return .completed },
        ], identifier: 500)
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
        
        let subscriptions = Subscriptions()
        subscriptions.publish(0x7)
        
        let readFilesBlock = LintTable.Sequential(lints: [
            // Data Sources don't receive subscriptions
            { [/*unowned*/ self, subscriptions] _ in
                let outputStreams: SubscriptionMask = 0x3
                
                switch readFiles.next() {
                case .notAvailable:
                    subscriptions.unpublish(outputStreams)
                 case .eof:
                    subscriptions.exhaust(outputStreams)
                case .proceed:
                    subscriptions.publish(outputStreams)
                case .unusualExecutionEvent:
                    assert(executionContext.pendingEvent != nil)
                    return .unusualExecutionEvent(executionContext.pendingEvent!)
                }
                
                return .running
            },
        ])
        
        let skipOutputBlock = {
            let inputSubscriptions: SubscriptionMask = 0x1
            let outputStreams: SubscriptionMask = 0x3
            
            return LintTable.Sequential(lints: [
                { [subscriptions] _ in
                    guard !subscriptions.areAllExhausted() else { return .nonLocalBreak(2) }
                    
                    guard subscriptions.areAllAvailable(inputSubscriptions) else {
                        subscriptions.unpublish(outputStreams)
                        return .localBreak
                    }
                    
                    return .running
                },
                { [/*unowned*/ self, subscriptions] _ in
                    switch skipOutput.include() {
                    case .notAvailable:
                        subscriptions.unpublish(outputStreams)
                    case .eof:
                        subscriptions.unpublish(outputStreams)
                        return .unusualExecutionEvent(.warning("Filter emitted .eof unexpectedly"))
                    case .proceed:
                        break  // continue tick
                    case .unusualExecutionEvent:
                        assert(executionContext.pendingEvent != nil)
                        return .unusualExecutionEvent(executionContext.pendingEvent!)
                    }
                    
                    return .running
                },
            ])
        }()
        
        let processFileBlock = {
            let inputSubscriptions: SubscriptionMask = 0x2
            let outputStreams: SubscriptionMask = 0x4
            
            return LintTable.Sequential(lints: [
                { [subscriptions] _ in
                    guard !subscriptions.areAllExhausted() else { return .nonLocalBreak(2) }
                    
                    guard subscriptions.areAllAvailable(inputSubscriptions) else {
                        subscriptions.unpublish(outputStreams)
                        return .localBreak
                    }
                    
                    return .running
                },
                { [/*unowned*/ self, subscriptions, fileContext] _ in
                    guard let pathname = try? executionContext["pathname"].get()! else {
                        return .unusualExecutionEvent(.exception("subscription access error."))
                    }
                    
                    fileContext["filename"] = .success(pathname)
                    
                    let processFile = Comprehension_ProcessFile(executionContext: fileContext)
                    let result = processFile.execute()
                    
                    switch result {
                    case .notAvailable:
                        subscriptions.unpublish(outputStreams)
                    case .eof:
                        subscriptions.exhaust(outputStreams)
                    case .proceed:
                        break
                    case .unusualExecutionEvent:
                        executionContext.triggerUnusualEvent(fileContext.pendingEvent!)
                        return .unusualExecutionEvent(executionContext.pendingEvent!)
                    }
                    return .running
                },
            ])
        }()
        
        let synchronizeBlock = {
            let inputSubscriptions: SubscriptionMask = 0x4
            let outputStreams: SubscriptionMask = 0x8

            return LintTable.Sequential(lints: [
                { [subscriptions] _ in
                    guard !subscriptions.areAllExhausted() else { return .nonLocalBreak(2) }

                    guard subscriptions.areAllAvailable(inputSubscriptions) else {
                        subscriptions.unpublish(outputStreams)
                        return .localBreak
                    }
                    
                    return .running
                },
                { [/*unowned*/ self,subscriptions] _ in
                    
                    guard subscriptions.areAllAvailable(inputSubscriptions) else {                    subscriptions.unpublish(outputStreams)
                        return .running
                    }
                    
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
                        subscriptions.unpublish(outputStreams)
                    case .eof:
                        subscriptions.exhaust(outputStreams)
                    case .proceed:
                        break  // continue tick
                    case .unusualExecutionEvent:
                        assert(executionContext.pendingEvent != nil)
                        return .unusualExecutionEvent(executionContext.pendingEvent!)
                    }
                    
                    return .nonLocalBreak(2)
                },
            ])}()
        
        return LintTable.Sequential(lints: [
            { [readFilesBlock] in $0.pushSuboperation(table: readFilesBlock); return .skipYield },
            { [skipOutputBlock] in $0.pushSuboperation(table: skipOutputBlock); return .skipYield },
            { [processFileBlock] in $0.pushSuboperation(table: processFileBlock); return .skipYield },
            { [synchronizeBlock] in $0.pushSuboperation(table: synchronizeBlock); return .skipYield },
        ])
    }
    
    @inline(__always)
    private func produceMainLoop () -> LintTable.Steppable {
        return LintTable.Loop(lints: [
            { [/*unowned*/ self] in $0.pushSuboperation(table: produceTickFlow()); return .skipYield },
            { [/*unowned*/ self] _ in executionContext.endTick(); return .completed }, // continue to loop
        ], identifier: 2)
    }
}
