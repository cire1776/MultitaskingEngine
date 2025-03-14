// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import Atomics  // ✅ Atomic counters for accurate benchmarking

//@main
struct SBenchmarkApp {
    static func main() async {
        print("🚀 Starting Benchmark...\n")

        let iterations = 1_000_000_000  // **1 BILLION iterations**
        let counter = ManagedAtomic(0)  // ✅ Atomic counter to prevent optimizations

        let startTime = DispatchTime.now()

        @inline(__always)  // ✅ Forces inlining for accurate measurements
        func performWork(_ step: UInt64) {
            counter.wrappingIncrement(ordering: .relaxed)  // ✅ Atomic increment
        }

        await Task(priority: .high) {  // ✅ Run in high-priority task
            for _ in 0..<iterations {
                performWork(1)
            }
        }.value  // ✅ Wait for task to complete

        let endTime = DispatchTime.now()

        let elapsedNanoseconds = Double(endTime.uptimeNanoseconds - startTime.uptimeNanoseconds)
        let opsPerSecond = elapsedNanoseconds > 0
            ? Double(iterations) / (elapsedNanoseconds / 1_000_000_000)
            : Double(iterations)

        print("🔥 Executed \(iterations) iterations in \(elapsedNanoseconds) ns (\(opsPerSecond) OPS)\n")
    }
}

// run this
