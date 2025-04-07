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
    
    public var subscriptions = Subscriptions(sources: 0x01)
    
    private lazy var flowGraph = FlowEntity.graphFlow(self, for: flowEntities)

    public let mainLoopID: Int = 2
    public let tickFlowID: Int = 1
    
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
    
    public func readFilesBlock(nextEntity: LintTable.Steppable?) -> LintTable.Steppable {
        let outputStreams: SubscriptionMask = 0x3
        var result: EntityResult = .proceed

        return LintTable.Sequential(lints: [
            // Data Sources don't receive subscriptions
            { [self] _ in result = readFiles.next(); return .running },
            { [self] _ in dispatch(on: result, emitting: outputStreams) },
        ], identifier: 1776)
    }

    public func skipOutputBlock (nextEntity: LintTable.Steppable?) -> LintTable.Steppable {
        let inputSubscriptions: SubscriptionMask = 0x1
        let outputStreams: SubscriptionMask = 0x3
        var result: EntityResult = .proceed

        return LintTable.Sequential(lints: [
            { [self] _ in subscriptionGuard(using: inputSubscriptions, emitting: outputStreams) },
            { [self] _ in result = skipOutput.include(); return .running },
            { [self] _ in dispatch(on: result, emitting: outputStreams) },
        ], identifier: 1777)
    }

    public func processFileBlock(nextEntity: LintTable.Steppable?) -> LintTable.Steppable {
        let inputSubscriptions: SubscriptionMask = 0x2
        let outputStreams: SubscriptionMask = 0x4
        var result: EntityResult = .proceed

        return LintTable.Sequential(lints: [
            { [self] _ in subscriptionGuard(using: inputSubscriptions, emitting: outputStreams) },
            { [self] _ in
                guard let pathname = try? executionContext["pathname"].get()! else {
                    return .unusualExecutionEvent(.exception("subscription access error."))
                }
                
                fileContext["filename"] = .success(pathname)
                
                let processFile = Comprehension_ProcessFile(executionContext: fileContext)
                result = processFile.execute()
                print("----------- output: \(try! fileContext["output"].get()!) -----------")
                return .running
            },
            { [self] _ in dispatch(on: result, emitting: outputStreams) }
        ], identifier: 1778)
    }

    public func synchronizeBlock(nextEntity: LintTable.Steppable?) -> LintTable.Steppable {
        let inputSubscriptions: SubscriptionMask = 0x4
        let outputStreams: SubscriptionMask = 0x8
        var result: EntityResult = .proceed

        return LintTable.Sequential(lints: [
            { [self] _ in subscriptionGuard(using: inputSubscriptions, emitting: outputStreams) },
            { [self] _ in
                let sync = Synchronize(
                    aliasMap: [
                        "input": "output",
                        "output": "contents"
                    ],
                    source: fileContext,
                    destination: executionContext,
                )
                
                result = sync.process()
                return .running
            },
            { [self] _ in dispatch(on: result, emitting: outputStreams) },

        ], identifier: 1779)
    }
    
    lazy var flowEntities = [
        { [self] in readFilesBlock(nextEntity: $0) },
        { [self] in skipOutputBlock(nextEntity: $0) },
        { [self] in processFileBlock(nextEntity: $0) },
        { [self] in synchronizeBlock(nextEntity: $0) },
    ]
    
    @inline(__always)
    private func produceTickFlow() -> LintTable.Steppable {
        let current = flowGraph
        
        return LintTable.Sequential(lints: flowEntities.map { block in
            {
                $0.pushSuboperation(table: block(current?.next?.table))
                return MultitaskingEngine.OperationState.skipYield
            }
        }, identifier: tickFlowID)
    }
    
    lazy var tickFlow: LintTable.Steppable = produceTickFlow()
    
    @inline(__always)
    private func produceMainLoop() -> LintTable.Steppable {
        return LintTable.Loop(lints: [
            { [/*unowned*/ self] _ in self.subscriptions.reset(); return .running },
            { [/*unowned*/ self] in $0.pushSuboperation(table: tickFlow); return .skipYield },
            { [/*unowned*/ self] _ in executionContext.endTick(); return .completed }, // continue to loop
        ], identifier: mainLoopID)
    }
}
