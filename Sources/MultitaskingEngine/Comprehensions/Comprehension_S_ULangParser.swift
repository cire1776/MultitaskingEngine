//
//  Comprehension_S_ULangParser.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 4/5/25.
//

/*
 ULangParser = => subscription {
     from emit line ->
     emit character ->
     identify_symbols ->
     collect groups ->
     detect delimiters ->
     convert groups into tokens ->
     build ast.
 }
 */

import Foundation

final class Comprehension_S_ULangParser: Comprehension.Subscription {
    var context: SubscriptionStreamExecutionContext
    var executionContext: StreamExecutionContext
    
    var table: any LintTable.Steppable
    
    var operationID: Int = UUID().hashValue
    
    var mainLoopID: Int = 2
    var tickFlowID: Int = 1
    
    public var pumpers: [Int] = []
    
    private let emitLine: EmitStringWithReturns
    private let emitCharacter: EmitCharacter
    private let identifySymbol: IdentifySymbols
    private let collect: Collect
    private let build: BuildAST
    private let debugStream: DebugStream
    
    private lazy var tickFlowEntityBlocks = [
        { [self] in emitBlock(runner: $0) },
        { [self] in emitCharacterBlock(runner: $0) },
        { [self] in identifySymbolBlock(runner: $0) },
        { [self] in collectBlock(runner: $0) },
        { [self] in buildBlock(runner: $0) },
        { [self] in debugBlock(runner: $0) },
    ]
    
    required public init(executionContext: StreamExecutionContext? = nil) {
        guard executionContext == nil || executionContext is SubscriptionStreamExecutionContext else {
            fatalError("Expected a SubscriptionStreamExecutionContext!")
        }
        
        self.executionContext = executionContext!
        self.context = executionContext as! SubscriptionStreamExecutionContext
        
        self.emitLine = EmitStringWithReturns(executionContext: executionContext!,subscriptions: 0x0, publishes: 0x1)
        self.emitCharacter = EmitCharacter(aliasMap: ["input": "output"], executionContext: executionContext!,subscriptions: 0x1, publishes: 0x1)
        self.identifySymbol = IdentifySymbols(aliasMap: ["input": "output"], executionContext: executionContext!,subscriptions: 0x1, publishes: 0x1)
        self.collect = Collect(aliasMap: ["input": "output", "output": "group"], executionContext: executionContext!,subscriptions: 0x1, publishes: 0x2)
        self.build = BuildAST(aliasMap: ["input": "group", "output": "ast"], executionContext: executionContext!,subscriptions: 0x1, publishes: 0x2)
        self.debugStream = DebugStream(executionContext: executionContext!,subscriptions: 0x2, publishes: 0x4)

        self .table = LintTable.Sequential(lints: [], identifier: 0)
        
        self.table = LintTable.Sequential(lints: [
            { [self] _ in emitLine.initialize(); return .running },
            { [self] in $0.pushSuboperation(table: produceMainLoop(tickFlowEntityBlocks: tickFlowEntityBlocks)); return .skipYield },
            { [self] _ in
                build.finalize()
                return .completed }
        ], identifier: 500)
        
        self.context.subscriptions = Subscriptions(sources: 0x1)
    }
    
    @inline(__always)
    private func emitBlock(runner: LintRunner? = nil) -> LintTable.Steppable {
        var result: EntityResult = .proceed
        let outputStreams: SubscriptionMask = 0x1
        
        return LintTable.Sequential(lints: [
            { [self] _ in result = emitLine.next(); return .running },
            { [self] _ in dispatch(on: result, emitting: outputStreams) }
        ])
    }

    @inline(__always)
    private func emitCharacterBlock(runner: LintRunner) -> LintTable.Steppable {
        let inputStreams: SubscriptionMask = 0x1
        let outputStreams: SubscriptionMask = 0x1
        var result: EntityResult = .proceed

        return LintTable.Sequential(lints: [
            { [self] _ in subscriptionGuard(using: inputStreams, emitting: outputStreams) },
            { [self] _ in result = emitCharacter.process(); return .running },
            { [self] _ in dispatch(on: result, using: inputStreams, emitting: outputStreams, on: runner) }
        ])
    }

    @inline(__always)
    private func identifySymbolBlock(runner: LintRunner) -> LintTable.Steppable {
        let inputStreams: SubscriptionMask = 0x1
        let outputStreams: SubscriptionMask = 0x1
        var result: EntityResult = .proceed

        return LintTable.Sequential(lints: [
            { [self] _ in subscriptionGuard(using: inputStreams, emitting: outputStreams) },
            { [self] _ in result = identifySymbol.process(); return .running },
            { [self] _ in dispatch(on: result, using: inputStreams, emitting: outputStreams) }
        ])
    }

    @inline(__always)
    private func collectBlock(runner: LintRunner) -> LintTable.Steppable {
        let inputStreams: SubscriptionMask = 0x1
        let outputStreams: SubscriptionMask = 0x2
        var result: EntityResult = .proceed

        return LintTable.Sequential(lints: [
            { [self] _ in drainableSubscriptionGuard(using: inputStreams, emitting: outputStreams) },
            { [self] _ in result = executionContext.isDraining ? collect.drain(publishes: outputStreams) : collect.process(); return .running },
            { [self] _ in dispatch(on: result, using: inputStreams, emitting: outputStreams, on: runner) }
        ])
    }

    @inline(__always)
    private func buildBlock(runner: LintRunner) -> LintTable.Steppable {
        let inputStreams: SubscriptionMask = 0x2
        
        let outputStreams: SubscriptionMask = 0x4
        var result: EntityResult = .proceed

        return LintTable.Sequential(lints: [
            { [self] _ in drainableSubscriptionGuard(using: inputStreams, emitting: outputStreams) },
            { [self] _ in result = executionContext.isDraining ? build.drain() : build.process(); return .running },
            { [self] _ in dispatch(on: result, using: inputStreams, emitting: outputStreams) }
        ])
    }
    
    @inline(__always)
    private func debugBlock(runner: LintRunner) -> LintTable.Steppable {
        return LintTable.Sequential(lints: [
            { [self] _ in dispatch(on: debugStream.process()) }
        ])
    }
}

