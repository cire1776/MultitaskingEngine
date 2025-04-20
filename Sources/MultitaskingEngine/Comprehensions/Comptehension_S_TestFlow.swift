//
//  Comptehension_S_TestFlow.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 4/6/25.
//

//
// ULang Source:
// define test_flow as comprehension {
//     emit string "hello world\nthis is a test"
//     -> split lines into words
//     -> join words with ","
//     -> print words.
// }

import Foundation

internal final class Comprehension_S_TestFlow: Comprehension.Subscription {
    var context: SubscriptionStreamExecutionContext
    var executionContext: StreamExecutionContext

    var table: any LintTable.Steppable

    var operationID: Int = UUID().hashValue

    var mainLoopID: Int = 2
    var tickFlowID: Int = 1

    public var pumpers: [Int] = []

    private let emitString: EmitString!
    private let split: SplitLinesIntoWords
    private let join: JoinWordsWithComma
    private let printer: Print

    required public init(executionContext: StreamExecutionContext?=nil) {
        guard executionContext == nil || executionContext is SubscriptionStreamExecutionContext else {
            fatalError("Expected a SubscriptionStreamExecutionContext!")
        }

        let executionContext = executionContext ?? SubscriptionStreamExecutionContext()

        self.executionContext = executionContext
        self.context = self.executionContext as! SubscriptionStreamExecutionContext
        self.executionContext.subscriptions = Subscriptions(sources: 0x07)

        self.emitString = EmitString(executionContext: executionContext, subscriptions: 0x0, publishes: 0x1)

        self.split = SplitLinesIntoWords(aliasMap: ["input": "output", "output": "words"], executionContext: executionContext, subscriptions: 0x1, publishes: 0x2)
        self.join = JoinWordsWithComma(aliasMap: ["input": "words", "output": "comma_delimited_line"], executionContext: executionContext, subscriptions: 0x4, publishes: 0x4)
        self.printer = Print(aliasMap: ["input": "comma_delimited_line"], executionContext: executionContext, subscriptions: 0x4, publishes: 0x0)

        self.table = LintTable.Sequential(lints: [])

        self.table = LintTable.Sequential(lints: [
            { [self] _ in emitString.initialize() ; return .running },
            { [self] in $0.pushSuboperation(table: produceMainLoop(tickFlowEntityBlocks: tickFlowEntityBlocks)); return .skipYield },
            { _ in print("Concatenation complete! Output saved in: output.txt" ); return .running },
            { [self] _ in join.finalize() ; return .completed }

        ], identifier: 500)

        self.executionContext.subscriptions = Subscriptions(sources: 0x1)
    }

    func instantiate(preinitialization_specifier: LintSpecifier?, executionContext: StreamExecutionContext?) -> Comprehension.Instance {
        return Comprehension.Instance(blueprint: self, preinitializationSpecifier: preinitialization_specifier, executionContext: executionContext)
    }

    @inline(__always)
    private func emitBlock(runner: LintRunner?=nil) -> LintTable.Steppable {
        let outputStreams: SubscriptionMask = 0x1
        var result: EntityResult = .proceed

        return LintTable.Sequential(lints: [
            { [self] _ in print("----- Emitting block\(executionContext.executionMode.rawValue) -----"); return .running },
            { [self] _ in result = emitString.next(); return .running },
            { [self] _ in dispatch(on: result, emitting: outputStreams) }
        ])
    }

    @inline(__always)
    private func splitBlock(runner: LintRunner) -> LintTable.Steppable {
        let inputStreams: SubscriptionMask = 0x1
        let outputStreams: SubscriptionMask = 0x2
        var result: EntityResult = .proceed

        return LintTable.Sequential(lints: [
            { [self] _ in print("----- Split block\(executionContext.executionMode.rawValue) -----"); return .running },
            { [self] _ in drainableSubscriptionGuard(using: inputStreams, emitting: outputStreams) },
            { [self] _ in result = split.process(); return .running },
            { [self] _ in dispatch(on: result, using: inputStreams, emitting: outputStreams, on: runner) }
        ])
    }

    @inline(__always)
    private func joinBlock(runner: LintRunner?=nil) -> LintTable.Steppable {
        let inputStreams: SubscriptionMask = 0x2
        let outputStreams: SubscriptionMask = 0x4
        var result: EntityResult = .proceed

        return LintTable.Sequential(lints: [
            { [self] _ in print("----- join block\(executionContext.executionMode.rawValue) -----"); return .running },
            { [self] _ in drainableSubscriptionGuard(using: inputStreams, emitting: outputStreams) },
            { [self] _ in result = executionContext.isDraining ? join.drain() : join.process(); return .running },
            { [self] _ in dispatch(on: result, using: inputStreams, emitting: outputStreams) }
        ])
    }

    @inline(__always)
    private func printBlock(runner: LintRunner?=nil) -> LintTable.Steppable {
        let inputStreams: SubscriptionMask = 0x4

        return LintTable.Sequential(lints: [
            { [self] _ in print("----- print block\(executionContext.executionMode.rawValue) -----"); return .running },
            { [self] _ in subscriptionGuard(using: inputStreams, emitting: 0) },
            { [self] _ in _ = printer.process(); return .running }
        ])
    }

    private lazy var tickFlowEntityBlocks = [
        { [self] in emitBlock(runner: $0) },
        { [self] in splitBlock(runner: $0) },
        { [self] in joinBlock(runner: $0) },
        { [self] in printBlock(runner: $0) }
    ]
}
