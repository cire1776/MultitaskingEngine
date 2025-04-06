//
//  ComprehensionSubscriptionTests.swift
//  MultitaskingEngineTests
//
//  Created by Eric Russell on 04/04/25.
//

import Quick
import Nimble
@testable import MultitaskingEngine
@testable import TestHelpers

// Dummy implementation of Comprehension.Subscription for testing.
class DummySubscription: Comprehension.Subscription {
    var executionContext: StreamExecutionContext
    var table: LintTable.Steppable
    var operationID: Int = 0
    // For a Subscription, the extension should prefix the operation name with "Comprehension_S_"
    var operationName: String = "Comprehension_S_0"
    
    var subscriptions: MultitaskingEngine.Subscriptions
    
    var mainLoopID: Int = 9999 // none actually used
    
    init(ctx: StreamExecutionContext) {
        self.executionContext = ctx
        // Create a simple sequential lint table with one no‑op lint that returns .running.
        self.table = LintTable.Sequential(lints: [
            { _ in return .running }
        ], identifier: 0)
        self.subscriptions = Subscriptions()
    }
    
    func instantiate(preinitialization_lint: Lint?, executionContext: StreamExecutionContext?) -> Comprehension.Instance {
        return Comprehension.Instance(blueprint: self, preinitializationLint: preinitialization_lint, executionContext: executionContext)
    }
}

final class ComprehensionSubscriptionTests: AsyncSpec {
    override class func spec() {
        describe("Comprehension.Subscription") {
            var ctx: StreamExecutionContext!
            var dummySub: DummySubscription!
            
            beforeEach {
                ctx = StreamExecutionContext()
                dummySub = DummySubscription(ctx: ctx)
            }
            
            context("Operation name") {
                it("formats the operation name with the subscription prefix") {
                    // Our Subscription extension is expected to prefix the name with "Comprehension_S_"
                    let expected = "Comprehension_S_\(String(format: "%X", dummySub.operationID))"
                    expect(dummySub.operationName).to(equal(expected))
                }
            }
            
            context("Instantiation") {
                it("uses the provided execution context if one is given") {
                    let customCtx = StreamExecutionContext()
                    let instance = dummySub.instantiate(preinitialization_lint: nil, executionContext: customCtx)
                    expect(instance.executionContext).to(beIdenticalTo(customCtx))
                }
                
                it("defaults to the blueprint's execution context if none is provided") {
                    // In our dummy, the blueprint already has its executionContext set to ctx.
                    let instance = dummySub.instantiate(preinitialization_lint: nil, executionContext: nil)
                    expect(instance.executionContext).to(beIdenticalTo(ctx))
                }
            }
            
            context("Preinitialization lint insertion") {
                it("executes preinitialization lint before main lints in order") {
                    var output: [String] = []
                    
                    // Preinitialization lint: appends "preinit" and returns .firstRun.
                    let preinitLint: Lint = { _ in
                        output.append("preinit")
                        return .firstRun
                    }
                    
                    // Main lint: appends "main" and returns .completed.
                    let mainLint: Lint = { _ in
                        output.append("main")
                        return .completed
                    }
                    
                    // Create a dummy subscription blueprint with a main lint table containing only the main lint.
                    let dummySub = DummySubscription(ctx: ctx)
                    dummySub.table = LintTable.Sequential(lints: [mainLint], identifier: 1)
                    
                    // Instantiate the subscription instance with the preinitialization lint.
                    let instance = dummySub.instantiate(preinitialization_lint: preinitLint, executionContext: ctx)
                    
                    // Execute the instance using the ManualLintRunner.
                    let runner = ManualLintRunner(provider: DummyLintProvider(table: instance.table))
                    let result = await runner.executeAll()
                    
                    expect(result).to(equal(.completed))
                    expect(output).to(equal(["preinit", "main"]))
                }
                
                context("ManualLintRunner execution") {
                    it("executes a simple subscription lint chain and returns .completed") {
                        // Build a subscription blueprint with two lints:
                        // The first appends "sub1" and returns .running,
                        // The second appends "sub2" and returns .completed.
                        var output: [String] = []
                        let lint1: Lint = { _ in output.append("sub1"); return .running }
                        let lint2: Lint = { _ in output.append("sub2"); return .completed }
                        
                        // Create a sequential lint table for the subscription.
                        let subTable = LintTable.Sequential(lints: [lint1, lint2], identifier: 10)
                        dummySub.table = subTable
                        
                        // Instantiate a subscription instance.
                        let instance = dummySub.instantiate(preinitialization_lint: nil, executionContext: ctx)
                        
                        // Execute using ManualLintRunner.
                        let runner = ManualLintRunner(provider: DummyLintProvider(table: instance.table))
                        let result = await runner.executeAll()
                        
                        expect(result).to(equal(.completed))
                        expect(output).to(equal(["sub1", "sub2"]))
                    }
                }
            }
        }
    }
}
