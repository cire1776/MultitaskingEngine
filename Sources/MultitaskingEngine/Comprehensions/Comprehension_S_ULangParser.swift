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

final public class Comprehension_S_ULangParser: Comprehension.Subscription {
    public var context: SubscriptionStreamExecutionContext
    public var executionContext: StreamExecutionContext

    public var table: any LintTable.Steppable

    public var operationID: Int = UUID().hashValue

    public var mainLoopID: Int = 2
    public var tickFlowID: Int = 1

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
        { [self] in debugBlock(runner: $0) }
    ]

    required public init(executionContext: StreamExecutionContext? = nil) {
        let actualContext: SubscriptionStreamExecutionContext

        if let incomingContext = executionContext {
            guard let casted = incomingContext as? SubscriptionStreamExecutionContext else {
                fatalError("Expected a SubscriptionStreamExecutionContext!")
            }
            actualContext = casted
        } else {
            actualContext = SubscriptionStreamExecutionContext()
        }

        self.executionContext = actualContext
        self.context = actualContext

        self.emitLine = EmitStringWithReturns(executionContext: self.executionContext, subscriptions: 0x0, publishes: 0x1)
        self.emitCharacter = EmitCharacter(aliasMap: ["input": "output"], executionContext: self.executionContext, subscriptions: 0x1, publishes: 0x1)
        self.identifySymbol = IdentifySymbols(aliasMap: ["input": "output"], executionContext: self.executionContext, subscriptions: 0x1, publishes: 0x1)
        self.collect = Collect(aliasMap: ["input": "output", "output": "group"], executionContext: self.executionContext, subscriptions: 0x1, publishes: 0x2)
        self.build = BuildAST(aliasMap: ["input": "group", "output": "ast"], executionContext: self.executionContext, subscriptions: 0x1, publishes: 0x2)
        self.debugStream = DebugStream(executionContext: self.executionContext, subscriptions: 0x2, publishes: 0x4)

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

        return LintTable.Sequential(specifiers: [
            .init({ [self] _ in result = emitLine.next(); return .running }, name: "emitLine", description: "emits a single line"),
            .init({ [self] _ in dispatch(on: result, emitting: outputStreams) }, name: "emitLine Dispatch")
        ])
    }

    @inline(__always)
    private func emitCharacterBlock(runner: LintRunner) -> LintTable.Steppable {
        let inputStreams: SubscriptionMask = 0x1
        let outputStreams: SubscriptionMask = 0x1
        var result: EntityResult = .proceed

        return LintTable.Sequential(specifiers: [
            .init({ [self] _ in subscriptionGuard(using: inputStreams, emitting: outputStreams) },
                  name: "emitCharacter.guard", description: "Verifies subscriptions are valid"),
            .init({ [self] _ in result = emitCharacter.process(); return .running },
                  name: "emitCharacter.process", description: "Parses one character into a token"),
            .init({ [self] _ in dispatch(on: result, using: inputStreams, emitting: outputStreams, on: runner) },
                  name: "emitCharacter.dispatch", description: "Routes output based on result")
        ])
    }

    @inline(__always)
    private func identifySymbolBlock(runner: LintRunner) -> LintTable.Steppable {
        let inputStreams: SubscriptionMask = 0x1
        let outputStreams: SubscriptionMask = 0x1
        var result: EntityResult = .proceed

        return LintTable.Sequential(specifiers: [
            .init({ [self] _ in subscriptionGuard(using: inputStreams, emitting: outputStreams) },
                  name: "identifySymbol.guard"),
            .init({ [self] _ in result = identifySymbol.process(); return .running },
                  name: "identifySymbol.process"),
            .init({ [self] _ in dispatch(on: result, using: inputStreams, emitting: outputStreams) },
                  name: "identifySymbol.dispatch")
        ])
    }

    @inline(__always)
    private func collectBlock(runner: LintRunner) -> LintTable.Steppable {
        let inputStreams: SubscriptionMask = 0x1
        let outputStreams: SubscriptionMask = 0x2
        var result: EntityResult = .proceed

        return LintTable.Sequential(specifiers: [
            .init({ [self] _ in drainableSubscriptionGuard(using: inputStreams, emitting: outputStreams) },
                  name: "collect.guard", description: "Ensures stream state is valid for collection"),
            .init({
                [self] _ in result = executionContext.isDraining
                    ? collect.drain(publishes: outputStreams)
                    : collect.process()
                return .running
            }, name: "collect.process", description: "Performs collection or draining based on mode"),
            .init({ [self] _ in dispatch(on: result, using: inputStreams, emitting: outputStreams, on: runner) },
                  name: "collect.dispatch", description: "Dispatches the collection result")
        ])
    }

    @inline(__always)
    private func buildBlock(runner: LintRunner) -> LintTable.Steppable {
        let inputStreams: SubscriptionMask = 0x2
        let outputStreams: SubscriptionMask = 0x4
        var result: EntityResult = .proceed

        return LintTable.Sequential(specifiers: [
            .init({ [self] _ in drainableSubscriptionGuard(using: inputStreams, emitting: outputStreams) },
                  name: "build.guard", description: "Ensures correct input/output before building"),
            .init({
                [self] _ in result = executionContext.isDraining
                    ? build.drain()
                    : build.process()
                return .running
            }, name: "build.process", description: "Builds or drains AST based on execution context"),
            .init({ [self] _ in dispatch(on: result, using: inputStreams, emitting: outputStreams) },
                  name: "build.dispatch", description: "Dispatches result of build step")
        ])
    }
    
    @inline(__always)
    private func debugBlock(runner: LintRunner) -> LintTable.Steppable {
        LintTable.Sequential(specifiers: [
            .init({ [self] _ in dispatch(on: debugStream.process()) }, name: "debug.dispatch", description: "Emits debug information")
        ])
    }
}
