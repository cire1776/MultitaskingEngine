//
//  linttablemain.swift
//  SwiftBenchmarks
//
//  Created by Eric Russell on 4/3/25.
//

import Foundation
import Shared
@testable import MultitaskingEngine

actor Status {
    var stopped = false
    
    public func stop() {
        stopped =  true
    }
}

public func whileTimeout(
    seconds: Double,
    condition: @Sendable @escaping () async -> Bool
) async -> Bool {
//    var conditionTask: Task<Bool,Never>!=nil
    let status = Status()
    
    // Define tasks BEFORE adding them to the group
    let timeoutTask = Task {
        let deadline = Date().addingTimeInterval(seconds)
        while Date().timeIntervalSince(deadline) < 0  {
            let stopped = await status.stopped
            if Task.isCancelled || stopped { return false }  // ✅ Stop early if cancelled
            try? await Task.sleep(nanoseconds: 5_000_000) // ✅ Reduce CPU load
        }
        await status.stop()
        return false // Timeout reached
    }

    let conditionTask = Task {
        while !Task.isCancelled {
            if await status.stopped { break }
            if await condition() {
                await status.stop()
                return true // Condition met, return early
            }
            await Task.yield() // ✅ Prevent blocking
        }
        await status.stop()
        return false // ✅ If cancelled, return false
    }
    
    let didFinish = await withTaskGroup(of: Bool.self) { group -> Bool in
        group.addTask { await conditionTask.value }
        group.addTask { await timeoutTask.value }

        return true
    }

    // ✅ Explicitly cancel both tasks after determining result
    timeoutTask.cancel()
    conditionTask.cancel()

    return didFinish
}

class DummyLintProvider: RunnableLintProvider {
    var table: LintTable.Steppable = LintTable.Sequential(lints: [])
    var operationName: String
    
    init(table: LintTable.Steppable, operationName: String?=nil) {
        self.table = table
        self.operationName = operationName ?? "DummyOperation"
    }
}

// A no‑op lint: It simply returns .running
nonisolated(unsafe) let nopLint: Lint = { _ in
    return .running
}

// Benchmark for a flat sequential lint table.
func benchmarkSequentialLintTable(iterations: Int) {
    // Create a lint array of 100 no‑op lints.
    let lints = Array(repeating: nopLint, count: 100)
    // Create a sequential lint table.
    let table = LintTable.Sequential(lints: lints, identifier: 0)
    // Instantiate a manual lint runner with the sequential table.
    let runner = ManualLintRunner(provider: DummyLintProvider(table: table))
    
    // Measure the execution time for a large number of steps.
    measureExecutionTime(label: "SequentialLintTable", iterations: iterations) {
        _ = runner.executeAll()
    }
}

// Benchmark for a loop lint table.
func benchmarkLoopLintTable(iterations: Int) {
    // Create a lint array of 100 no‑op lints.
    var lints = Array(repeating: nopLint, count: 100)
    lints.append({ _ in .completed })
    
    // Create a loop lint table.
    let table = LintTable.Loop(lints: lints, identifier: 0)
    // Instantiate a manual lint runner with the loop table.
    let runner = ManualLintRunner(provider: DummyLintProvider(table: table))
    
    // Measure the execution time for many execution steps.
    measureExecutionTime(label: "LoopLintTable", iterations: iterations) {
        _ = runner.executeAll()
    }
}

// Benchmark for a flat sequential lint table that appends to an output array.
func benchmarkSequentialLintTableAppending(iterations: Int) {
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
    
    // Create the ManualLintRunner with the sequential table.
    let runner = ManualLintRunner(provider: DummyLintProvider(table: table))
    
    // Benchmark the execution of a single step over many iterations.
    measureExecutionTime(label: "SequentialLintTableAppending", iterations: iterations) {
        _ = runner.executeAll()
    }
    
    var runner2 = ManualLintRunner(provider: DummyLintProvider(table: LintTable.Sequential(lints: [])))
    
    measureExecutionTime(label: "Base NOP Execution", iterations: iterations) {
        for _ in 0..<100 {
            _ = nopLint(runner2)
        }
    }
    
    var output2: [Int] = []
    measureExecutionTime(label: "Base Append Operation", iterations: iterations) {
        for _ in 0..<100 {
            { _ in output2.append(1) } (runner2)
        }
    }

}

// Benchmark for a loop lint table that appends to an output array.
func benchmarkLoopLintTableAppending(iterations: Int) {
    var output: [Int] = []

    let appendingLint: Lint = { _ in
        output.append(1)
        return .running
    }
    
    var lints = Array(repeating: appendingLint, count: 99)
    lints.append({ _ in .localBreak } )
    
    // Create a LoopLintTable. In our design, a loop table resets its counter when a lint returns .completed.
    let table = LintTable.Loop(lints: lints, identifier: 0)
    let runner = ManualLintRunner(provider: DummyLintProvider(table: table))
    
    measureExecutionTime(label: "LoopLintTableAppending", iterations: iterations) {
        _ = runner.executeAll()
    }
}

// A non‑trivial lint that does some arithmetic and sorting.
nonisolated(unsafe) let nonTrivialLint: Lint = { _ in
    // Sum numbers 1 through 1000.
    var sum = 0
    for i in 1...1000 {
        sum += i
    }
    // Sort a small array.
    var arr = [3, 1, 4, 1, 5, 9, 2, 6]
    arr.sort()
    // Use the results to prevent optimization from removing this work.
    if sum % 2 == 0 {
        _ = arr.first
    } else {
        _ = arr.last
    }
    return .running
}

func benchmarkNonTrivialLint(iterations: Int) {
    // Create an array of 100 non‑trivial lints.
    let lints = Array(repeating: nonTrivialLint, count: 100)
    
    // Build a SequentialLintTable (i.e. a flat, one‑pass table).
    let table = LintTable.Sequential(lints: lints, identifier: 0)
    
    // Instantiate a ManualLintRunner with the sequential table.
    let runner = ManualLintRunner(provider: DummyLintProvider(table: table))
    
    // Benchmark by executing the entire lint chain repeatedly.
    measureExecutionTime(label: "NonTrivialLintBenchmark", iterations: iterations) {
         _ = runner.executeAll()
    }
    
    measureExecutionTime(label: "Base NonTrivialLintBenchmark", iterations: iterations) {
        for _ in 0 ..< 100 {
            _ = nonTrivialLint(runner)
        }
    }

}

let OM = OperationManager()

// Run Execution Benchmark
@main
struct ExecutionBenchmarkApp {
    static func main() async {
        print("🚀 Starting MLR Execution Benchmarks...")
        // Run benchmarks with 1,000,000 iterations each.
        benchmarkSequentialLintTable(iterations: 1_000_000)
        benchmarkLoopLintTable(iterations: 1_000_000)
        
        benchmarkSequentialLintTableAppending(iterations: 1_000_000)
        benchmarkLoopLintTableAppending(iterations: 1_000_000)
        
        benchmarkNonTrivialLint(iterations: 1_000_000)

        print("🚀 Starting Operation/MTE Execution Benchmarks...")
        
        _ = await whileTimeout(seconds: 5) {
            await OM.isRunning == true
        }
        
        
        // Run benchmarks with 1,000,000 iterations each.
        await benchmarkOperationSequentialLintTable(iterations: 1_000_000)
        await benchmarkOperationLoopLintTable(iterations: 1_000_000)
        
        await benchmarkOperationSequentialLintTableAppending(iterations: 1_000_000)
        await benchmarkOperationLoopLintTableAppending(iterations: 1_000_000)
        
        await benchmarkOperationNonTrivialLint(iterations: 1_000_000)
    }
}
