//
//  LintTests.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 4/2/25.
//

import Quick
import Nimble
@testable import MultitaskingEngine
@testable import TestHelpers

final class LintTests: AsyncSpec {
    override class func spec() {
        describe("loop lint") {
            context("instantiation") {
                it("is instantiated by passing .loop and identifier to lint table") {
                    let loop = LintTable.Loop(lints: [])
                    expect(loop.lints).to(beEmpty())
                    expect(loop.identifier).to(equal(0))
                }
                
                it("can have a identifier") {
                    let loop = LintTable.Loop(lints: [],identifier: 1776)
                    expect(loop.identifier).to(equal(1776))
                }
            }
            
            describe("looping") {
                it("loops multiple times until broken") {
                    var output: [String] = []
                    var count = 1
                    
                    let loop = LintTable.Loop(lints: [
                        { _ in print("in loop: \(count)");if count > 100 { fatalError("opps!") }; output.append("hello \(count)"); count += 1; return count <= 6 ? .running : .localBreak },
                    ])
                    
                    let runner = ManualLintRunner(provider: DummyLintProvider(table: loop))
                    await _ = runner.executeAll()
                                        
                    expect(output).to(equal(["hello 1", "hello 2", "hello 3", "hello 4", "hello 5", "hello 6"]))
                }
                
                describe("breakLoop") {
                    it("terminates a loop") {
                        var output: [String] = []
                        
                        let loop = LintTable.Loop(lints: [
                            { _ in output.append("hello 1"); return .running },
                            { _ in output.append("hello 2"); return .localBreak },
                            { _ in output.append("hello 3"); return .completed },
                        ])
                        
                        let runner = ManualLintRunner(provider: DummyLintProvider(table: loop))
                        
                        var result = await runner.execute()
                        expect(result).to(equal(.running))
                        expect(output).to(equal(["hello 1"]))

                        result = await runner.execute()
                        expect(result).to(equal(.completed))
                        expect(output).to(equal(["hello 1","hello 2"]))
                    }
                }
                
                describe("local and non-local continuations") {
                    it(".complete terminates a loop iteration like a local continue") {
                        var output: [String] = []
                        
                        
                        var count = 1
                        
                        let loop = LintTable.Loop(lints: [
                            { _ in output.append("hello \(count)"); count += 1; return count < 3 ? .running : .completed },
                            { _ in output.append("hello \(count)"); count += 1; return count < 3 ? .running : .completed },
                        ])
                        
                        let runner = ManualLintRunner(provider: DummyLintProvider(table: loop))
                        var result = await runner.execute()
                        
                        expect(result).to(equal(.running))
                        expect(output).to(equal(["hello 1"]))

                        result = await runner.execute()
                        
                        expect(result).to(equal(.completed))
                        expect(output).to(equal(["hello 1", "hello 2"]))
                    }
                    
                    it(".nonLocalContinue terminates a loop iteration like a non-local continue") {
                        var output: [String] = []
                        
                        let loop_inner: LintTable.Loop = .init(lints: [
                            { _ in output.append("inner"); return .running },
                            { _ in .nonLocalContinue(2) }
                        ])
                        
                        let loop_middle: LintTable.Loop = .init(lints: [
                            { _ in output.append("middle"); return .running },
                            { $0.pushSuboperation(table: loop_inner); return .skipYield },
                        ], identifier:  1)
                        
                        let loop_outer: LintTable.Loop = .init(lints: [
                            { _ in output.append("outer first"); return .running },
                            { $0.pushSuboperation(table: loop_middle); return .skipYield },
                            { _ in print("in outer last"); output.append("outer last"); return .localBreak},
                        ], identifier: 2)

                        let runner = ManualLintRunner(provider: DummyLintProvider(table: loop_outer))
                        
                        var result = await runner.execute()
                        
                        expect(result).to(equal(.running))
                        expect(output).to(equal(["outer first"]))

                        result = await runner.execute()
                        
                        expect(result).to(equal(.running))
                        expect(output).to(equal(["outer first", "middle"]))

                        result = await runner.execute()
                        
                        expect(result).to(equal(.running))
                        expect(output).to(equal(["outer first", "middle", "inner"]))

                        result = await runner.execute()
                        
                        expect(result).to(equal(.completed))
                        expect(output).to(equal(["outer first", "middle", "inner", "outer last"]))

                    }
               }
            }
        }
    }
}
