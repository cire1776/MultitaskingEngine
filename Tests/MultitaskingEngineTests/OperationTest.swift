//
//  OperationTest.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 3/1/25.
//
import Quick
import Nimble
@testable import MultitaskingEngine
@testable import TestHelpers

final class OperationTest: AsyncSpec {
    override class func spec() {
        class DummyLintProvider: RunnableLintProvider {
            var table: LintTable = LintTable(lints: [])
            var operationName: String
            
            init(table: LintTable, operationName: String?=nil) {
                self.table = table
                self.operationName = operationName ?? "DummyOperation"
            }
        }
        
        it("updates state to .completed after execution") {
           let operation = MockOperation(operationName: "CompletingOperation", states: [.running, .completed])
            
            /// state is initial suspended
            expect(operation.state).to(equal(.suspended))
            
            _ = operation.execute()
            expect(operation.state).to(equal(.running))
            
            _ = operation.execute()
            
            expect(operation.state).to(equal(.completed))
        }
        
        final class Counter {
            private(set) var value: Int = 0

            func increment() {
                value += 1
            }
        }
        
        describe("Flat Operation") {
            it("executes all lints in order and increments shared counter") {
                let context = ExecutionContext()
                let counter = Counter()

                let operation = Operation(name: "", provider: DummyLintProvider(table: LintTable(lints: [
                    { _ in counter.increment(); return .running },
                    { _ in counter.increment(); return .running },
                    { _ in counter.increment(); return .completed }
                ])))
                
                while operation.execute() == .running {}

                expect(counter.value).to(equal(3))
            }
            
            it("stops execution on .completed") {
                let context = ExecutionContext()
                let counter = Counter()

                let operation = Operation(name: "", provider: DummyLintProvider(table: LintTable(lints: [
                    { _ in counter.increment(); return .running },
                    { _ in counter.increment(); return .completed },
                    { _ in counter.increment(); return .running }
                ])))

                while operation.execute() == .running {}

                expect(counter.value).to(equal(2))  // third lint should not run
            }
            
            it("propagates unusual execution event immediately") {
                let context = ExecutionContext()
                let operation = Operation(name: "", provider: DummyLintProvider(table: LintTable(lints: [
                    { _ in .unusualExecutionEvent(.exception("Boom")) }
                ])))

                let result = operation.execute()
                expect(result).to(equal(.unusualExecutionEvent(.exception("Boom"))))
            }
        }
        
        describe("nested operation execution") {
            it("executes a nested lint array in correct order") {
                var output: [String] = []
                
                // Define the nested lint sequence
                let subLints: LintArray = [
                    { _ in output.append("C"); return .running },
                    { _ in output.append("D"); return .completed }
                ]
                
                var operation: Operation! = nil  // placeholder for capture
                operation = Operation(name: "top", provider: DummyLintProvider(table: LintTable(lints: [
                    { _ in output.append("A"); return .running },
                    { _ in output.append("B"); return .running },
                    { $0.pushSuboperation(lints: subLints); return .running },
                    { _ in output.append("E"); return .completed }
                ])))
                
                var result: OperationState = .running
                var safety = 0
                
                while result == .running && safety < 20 {
                    result = operation.execute()
                    safety += 1
                }
                
                expect(output).to(equal(["A", "B", "C", "D", "E"]))
                expect(result).to(equal(.completed))
            }
            
            it("executes deeply nested operations") {
                var output: [String] = []
                _ = ExecutionContext()

                // Sub-suboperation (deepest)
                let subSub = Operation(name: "subSub", provider: DummyLintProvider(table: LintTable(lints: [
                    { _ in output.append("3"); return .running },
                    { _ in output.append("4"); return .completed }
                ])))

                // Suboperation (middle)
                var top: Operation! = nil
                var sub: Operation! = nil
                sub = Operation(name: "sub", provider: DummyLintProvider(table: LintTable(lints: [
                    { _ in output.append("2"); return .running },
                    { $0.pushSuboperation(lints: subSub.table.lints); return .running },
                    { _ in output.append("5"); return .completed }
                ])))
                
                // Top-level operation
                top = Operation(name: "top", provider: DummyLintProvider(table: LintTable(lints: [
                    { _ in output.append("1"); return .running },
                    { $0.pushSuboperation(lints: sub.table.lints); return .running },
                    { _ in output.append("6"); return .completed }
                ])))

                var result: OperationState = .running
                var safety = 0

                while result == .running && safety < 30 {
                    result = top.execute()
                    safety += 1
                }

                expect(output).to(equal(["1", "2", "3", "4", "5", "6"]))
                expect(result).to(equal(.completed))
            }
        }
        
        describe("ManualLintRunner") {
            var dummyProvider: DummyLintProvider!
            var runner: ManualLintRunner!
            
            beforeEach {
                dummyProvider = DummyLintProvider(table: LintTable(lints: []))
                runner = ManualLintRunner(provider: dummyProvider)
            }
            
            context("with an empty lint array") {
                it("returns .completed") {
                    dummyProvider.table.lints = []
                    expect(runner.execute()).to(equal(.completed))
                }
            }
            
            context("when all lints return .running or .completed") {
                beforeEach {
                    dummyProvider.table.lints = [
                        { _ in return .running },
                        { _ in return .completed }
                    ]
                }
                it("iterates through all lints and returns .completed") {
                    expect(runner.execute()).to(equal(.completed))
                }
            }
            
            context("when a lint returns .suspended") {
                beforeEach {
                    dummyProvider.table.lints = [
                        { _ in return .running },
                        { _ in return .suspended },
                        { _ in return .completed }
                    ]
                }
            }
            
            context("when a lint returns .unusualExecutionEvent") {
                beforeEach {
                    let testError = UnusualExecutionEvent.exception("Test error")
                    dummyProvider.table.lints = [
                        { _ in return .running },
                        { _ in return .unusualExecutionEvent(testError) },
                        { _ in return .completed }
                    ]
                    runner = ManualLintRunner(provider: dummyProvider)
                }
                
                it("stops execution and returns the unusualExecutionEvent") {
                    let result = runner.execute()
                    switch result {
                    case .unusualExecutionEvent(let error):
                        expect("\(error)").to(contain("Test error"))
                    default:
                        fail("Expected unusualExecutionEvent, but got \(result)")
                    }
                }
            }
        }
    }
}
