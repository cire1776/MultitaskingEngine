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
    public var context: SubscriptionStreamExecutionContext
    public var executionContext: StreamExecutionContext
    
    public var table: LintTable.Steppable
    
    public var operationID: Int
    
    public let readFiles: ReadFiles
    public let skipOutput: SkipFilter
    
    public let fileContext = StreamExecutionContext()
    
    public let mainLoopID: Int = 2
    public let tickFlowID: Int = 1
    
    public var pumpers: [Int] = []
    
    required public init(executionContext: StreamExecutionContext?=nil) {
        guard executionContext == nil || executionContext is SubscriptionStreamExecutionContext else {
            fatalError("Expected a SubscriptionStreamExecutionContext!")
        }
        
        let executionContext = executionContext ?? SubscriptionStreamExecutionContext()

        self.executionContext = executionContext
        self.context = self.executionContext as! SubscriptionStreamExecutionContext
        self.executionContext.subscriptions = Subscriptions(sources: 0x01)
        
        operationID = Int("1A5D27B4", radix: 16)!
        
        readFiles = ReadFiles(
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
            { [/*unowned*/ self] in $0.pushSuboperation(table: produceMainLoop(tickFlowEntityBlocks: flowEntities)); return .skipYield },
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
    }

    @inline(__always)
    private func finalize() {
        print("finalize")
        readFiles.finalize()
    }
    
    public func readFilesBlock(runner: LintRunner? = nil) -> LintTable.Steppable {
        let outputStreams: SubscriptionMask = 0x3
        var result: EntityResult = .proceed

        return LintTable.Sequential(lints: [
            // Data Sources don't receive subscriptions
            { [self] _ in result = readFiles.next(); return .running },
            { [self] _ in dispatch(on: result, emitting: outputStreams) },
        ], identifier: 1776)
    }

    public func skipOutputBlock (runner: LintRunner? = nil) -> LintTable.Steppable {
        let inputSubscriptions: SubscriptionMask = 0x1
        let outputStreams: SubscriptionMask = 0x3
        var result: EntityResult = .proceed

        return LintTable.Sequential(lints: [
            { [self] _ in subscriptionGuard(using: inputSubscriptions, emitting: outputStreams) },
            { [self] _ in result = skipOutput.include(); return .running },
            { [self] _ in dispatch(on: result, using: inputSubscriptions, emitting: outputStreams) },
        ], identifier: 1777)
    }

    public func processFileBlock(runner: LintRunner? = nil) -> LintTable.Steppable {
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
            { [self] _ in dispatch(on: result, using: inputSubscriptions, emitting: outputStreams) }
        ], identifier: 1778)
    }

    public func synchronizeBlock(runner: LintRunner? = nil) -> LintTable.Steppable {
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
                
                result = sync.process(publishes: outputStreams)
                return .running
            },
            { [self] _ in dispatch(on: result, using: inputSubscriptions, emitting: outputStreams) },

        ], identifier: 1779)
    }
    
    lazy var flowEntities: [(LintRunner) -> LintTable.Steppable] = [
        { [self] in readFilesBlock(runner: $0) },
        { [self] in skipOutputBlock(runner: $0) },
        { [self] in processFileBlock(runner: $0) },
        { [self] in synchronizeBlock(runner: $0) },
    ]
}

