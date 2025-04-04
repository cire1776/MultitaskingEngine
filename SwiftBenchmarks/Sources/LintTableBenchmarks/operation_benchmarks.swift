//
//  linttablemain.swift
//  SwiftBenchmarks
//
//  Created by Eric Russell on 4/3/25.
//

import Foundation
import Shared
@testable import MultitaskingEngine

// Benchmark for a flat sequential lint table.
func benchmarkOperationSequentialLintTable(iterations: Int) async {
    // Create a lint array of 100 no‑op lints.
    let lints = Array(repeating: nopLint, count: 100)
    // Create a sequential lint table.
    let table = LintTable.Sequential(lints: lints, identifier: 0)
    // Instantiate a manual lint operation with the sequential table.
    let operation = Operation(provider: DummyLintProvider(table: table))
    
    // Measure the execution time for a large number of steps.
    await measureExecutionTime_async(label: "SequentialLintTable", iterations: iterations) {
        _ = await OM.addOperation(operation)
    }
}

// Benchmark for a loop lint table.
func benchmarkOperationLoopLintTable(iterations: Int) async {
    // Create a lint array of 100 no‑op lints.
    var lints = Array(repeating: nopLint, count: 99)
    lints.append({ _ in .localBreak })
    // Create a loop lint table.
    let table = LintTable.Loop(lints: lints, identifier: 0)
    // Instantiate a manual lint operation with the loop table.
    let operation = Operation(provider: DummyLintProvider(table: table))
    
    // Measure the execution time for many execution steps.
    await measureExecutionTime_async(label: "LoopLintTable", iterations: iterations) {
        _ = await OM.addOperation(operation)
    }
}

// Benchmark for a flat sequential lint table that appends to an output array.
func benchmarkOperationSequentialLintTableAppending(iterations: Int) async {
    // Output array to capture the work done by lints.
    var output: [Int] = []
    
    // A lint that appends to the output array and returns .running.
    let appendingLint: Lint = { _ in
        output.append(1)
        return .running
    }
    
    // Create an array of 100 such lints.
    let lints = Array(repeating: appendingLint, count: 100)
    
    // Create a SequentialLintTable (i.e. a block that runs once over its lints).
    let table = LintTable.Sequential(lints: lints, identifier: 0)
    
    // Create the ManualLintoperation with the sequential table.
    let operation = Operation(provider: DummyLintProvider(table: table))
    
    // Benchmark the execution of a single step over many iterations.
    await measureExecutionTime_async(label: "SequentialLintTableAppending", iterations: iterations) {
        _ = await OM.addOperation(operation)
    }
    
    var operation2 = Operation(provider: DummyLintProvider(table: LintTable.Sequential(lints: [])))
    
    await measureExecutionTime_async(label: "Base NOP Execution", iterations: iterations) {
        for _ in 0..<100 {
            _ = nopLint(operation2)
        }
    }
    
    var output2: [Int] = []
    await measureExecutionTime_async(label: "Base Append Operation", iterations: iterations) {
        for _ in 0..<100 {
            { _ in output2.append(1) } (operation2)
        }
    }

}

// Benchmark for a loop lint table that appends to an output array.
func benchmarkOperationLoopLintTableAppending(iterations: Int) async {
    var output: [Int] = []

    let appendingLint: Lint = { _ in
        output.append(1)
        return .running
    }
    
    let lints = Array(repeating: appendingLint, count: 100)
    
    // Create a LoopLintTable. In our design, a loop table resets its counter when a lint returns .completed.
    let table = LintTable.Loop(lints: lints, identifier: 0)
    let operation = Operation(provider: DummyLintProvider(table: table))
    
    await measureExecutionTime_async(label: "LoopLintTableAppending", iterations: iterations) {
        _ = await OM.addOperation(operation)
    }
}

func benchmarkOperationNonTrivialLint(iterations: Int) async {
    // Create an array of 100 non‑trivial lints.
    let lints = Array(repeating: nonTrivialLint, count: 100)
    
    // Build a SequentialLintTable (i.e. a flat, one‑pass table).
    let table = LintTable.Sequential(lints: lints, identifier: 0)
    
    // Instantiate a ManualLintoperation with the sequential table.
    let operation = Operation(provider: DummyLintProvider(table: table))
    
    // Benchmark by executing the entire lint chain repeatedly.
    await measureExecutionTime_async(label: "NonTrivialLintBenchmark", iterations: iterations) {
        _ = await OM.addOperation(operation)
    }
    
    await measureExecutionTime_async(label: "Base NonTrivialLintBenchmark", iterations: iterations) {
        for _ in 0 ..< 100 {
            _ = nonTrivialLint(operation)
        }
    }
}
