import Quick
import Nimble
@testable import MultitaskingEngine
@testable import TestHelpers

final class LintTablePrefacedTests: QuickSpec {
    override class func spec() {
        describe("LintTable.Prefaced") {
            context("when the preface executes normally") {
                it("executes preface then main lints in order") {
                    // Each test now creates its own state.
                    var output: [String] = []
                    
                    // Define two preface lints locally.
                    let prefaceLint1: Lint = { _ in
                        output.append("preface1")
                        return .running
                    }
                    let prefaceLint2: Lint = { _ in
                        output.append("preface2")
                        return .completed
                    }
                    let prefaceLints: LintArray = [prefaceLint1, prefaceLint2]
                    
                    // Define the main lint.
                    let mainLint: Lint = { _ in
                        output.append("main")
                        return .completed
                    }
                    let mainLints: LintArray = [mainLint]
                    
                    // Create sequential lint tables for preface and main.
                    let prefaceTable = LintTable.Sequential(lints: prefaceLints, identifier: 1)
                    let mainTable = LintTable.Sequential(lints: mainLints, identifier: 2)
                    
                    // Build the prefaced lint table from the two tables.
                    let prefacedTable = LintTable.Prefaced(preface: prefaceTable, main: mainTable, identifier: 0)
                    
                    // Use our TestLintProvider and ManualLintRunner (which are part of our existing infrastructure).
                    let provider = DummyLintProvider(table: prefacedTable)
                    let runner = ManualLintRunner(provider: provider)
                    
                    let result = runner.executeAll()
                    expect(result).to(equal(.completed))
                    // Expect the output to be: "preface1", "preface2", then "main".
                    expect(output).to(equal(["preface1", "preface2", "main"]))
                }
            }
            
            context("when a preface lint triggers an unrecoverable error") {
                it("halts execution without running main lints") {
                    var output: [String] = []
                    
                    // Define an error-producing preface lint.
                    let errorLint: Lint = { _ in
                        output.append("errorPreface")
                        return .unusualExecutionEvent(.exception("Failure in preface"))
                    }
                    let prefaceLints: LintArray = [errorLint]
                    
                    let prefaceTable = LintTable.Sequential(lints: prefaceLints, identifier: 1)
                    
                    // Main lint remains the same.
                    let mainLint: Lint = { _ in
                        output.append("main")
                        return .completed
                    }
                    let mainLints: LintArray = [mainLint]
                    let mainTable = LintTable.Sequential(lints: mainLints, identifier: 2)
                    
                    let prefacedTable = LintTable.Prefaced(preface: prefaceTable, main: mainTable, identifier: 0)
                    let provider = DummyLintProvider(table: prefacedTable)
                    let runner = ManualLintRunner(provider: provider)
                    
                    let result = runner.execute()
                    expect(result).to(equal(.unusualExecutionEvent(.exception("Failure in preface"))))
                    // Only the error-producing preface should run.
                    expect(output).to(equal(["errorPreface"]))
                }
            }
        }
    }
}
