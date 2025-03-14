//
//  tests.swift
//  SwiftBenchmarks
//
//  Created by Eric Russell on 3/4/25.
//

//
//  tests.swift
//  SwiftBenchmarks
//
//  Created by Eric Russell on 3/4/25.
//

import Foundation
import Atomics
import Dispatch
import CQueue
import Shared  // ✅ Import Shared utilities

func main() {
    print("🚀 Running Variable Benchmarks...")

    // ✅ Global iteration count
    let iterations = 10_000_000

    // ✅ Prevent compiler optimizations
    var preventOptimization: Int = 0

    // ✅ Ensures function calls are not inlined
    @inline(never)
    func variableStore() -> Int {
        return Int.random(in: 1...100)  // ✅ Prevents constant folding
    }

    // ✅ Closure-based variable store (same logic as `variableStore`)
    let closureVariableStore: () -> Int = {
        return Int.random(in: 1...100)  // ✅ Prevents constant folding
    }

    // ✅ Function Pointer-based variable store
    let functionPointers: [() -> Int] = [variableStore, variableStore, variableStore]

    // ✅ Measure execution time helper
    func measureExecutionTime(label: String, iterations: Int, _ block: () -> Void) {
        let startTime = DispatchTime.now()
        block()
        let endTime = DispatchTime.now()
        
        let elapsedNanoseconds = Double(endTime.uptimeNanoseconds - startTime.uptimeNanoseconds)
        let elapsedSeconds = elapsedNanoseconds / 1_000_000_000
        let opsPerSecond = Double(iterations) / elapsedSeconds
        
        print("🔥 \(label) - Time: \(formatNumber(elapsedSeconds)) seconds, Ops/sec: \(formatNumber(opsPerSecond))")
    }

    // ✅ Function-Based Variable Lookup Test
    func testFunctionBasedVariableLookup(iterations: Int) {
        var functionLookupResult = 0
        measureExecutionTime(label: "Function-Based Variable Lookup", iterations: iterations) {
            for _ in 0..<iterations {
                functionLookupResult += variableStore()  // ✅ Ensures the function is actually called
            }
        }
        preventOptimization = functionLookupResult  // ✅ Prevents dead code elimination
    }

    // ✅ Closure-Based Variable Lookup Test
    func testClosureBasedVariableLookup(iterations: Int) {
        var closureLookupResult = 0
        measureExecutionTime(label: "Closure-Based Variable Lookup", iterations: iterations) {
            for _ in 0..<iterations {
                closureLookupResult += closureVariableStore()  // ✅ Ensures the closure is actually executed
            }
        }
        preventOptimization = closureLookupResult  // ✅ Prevents dead code elimination
    }

    // ✅ Function Pointer-Based Variable Lookup Test
    func testFunctionPointerVariableLookup(iterations: Int) {
        var functionPointerLookupResult = 0
        measureExecutionTime(label: "Function Pointer-Based Variable Lookup", iterations: iterations) {
            for i in 0..<iterations {
                functionPointerLookupResult += functionPointers[i % functionPointers.count]()  // ✅ Ensures function pointers are resolved
            }
        }
        preventOptimization = functionPointerLookupResult  // ✅ Prevents dead code elimination
    }

    // ✅ Run all variable benchmarks
    print("🚀 Running Variable Benchmarks with \(formatNumber(Double(iterations))) iterations...")
    
    testFunctionBasedVariableLookup(iterations: iterations)
    testClosureBasedVariableLookup(iterations: iterations)
    testFunctionPointerVariableLookup(iterations: iterations)

    // ✅ Atomic Variable Benchmark
    let atomicCounter = ManagedAtomic(0)
    measureExecutionTime(label: "Atomic Variable Increment", iterations: iterations) {
        DispatchQueue.concurrentPerform(iterations: iterations) { _ in
            atomicCounter.wrappingIncrement(ordering: .relaxed)
        }
    }
    print("🔥 Final Atomic Counter:", formatNumber(Double(atomicCounter.load(ordering: .relaxed))))

    // ✅ Actor-Based Variable Benchmark
    actor VariableStore {
        var value: Int = 0
        func set(_ newValue: Int) { value = newValue }
        func get() -> Int { return value }
    }

    let varStore = VariableStore()
    measureExecutionTime(label: "Actor-Based Variable Update", iterations: iterations) {
        DispatchQueue.concurrentPerform(iterations: iterations) { i in
            Task {
                await varStore.set(i)
            }
        }
    }
    Task {
        let finalValue = await varStore.get()
        print("🔥 Final Actor-Based Variable Value:", formatNumber(Double(finalValue)))
    }

    // ✅ C-Based Variable Store Benchmark
    let cVarStore = VariableStoreWrapper()
    measureExecutionTime(label: "C Variable Store Lookup", iterations: iterations) {
        DispatchQueue.concurrentPerform(iterations: iterations) { i in
            cVarStore.set(i)
            _ = cVarStore.get()
        }
    }
    print("🔥 C Variable Store Lookup Benchmark Completed!")
}

main()
