//
//  BenchmarkUtils.swift
//  SwiftBenchmarks
//
//  Created by Eric Russell on 3/4/25.
//

// Sources/Shared/BenchmarkUtils.swift

import Foundation

public func measureExecutionTime(label: String, iterations: Int, _ block: () -> Void) {
    let startTime = DispatchTime.now()
    block()
    let endTime = DispatchTime.now()

    let elapsedNanoseconds = Double(endTime.uptimeNanoseconds - startTime.uptimeNanoseconds)
    let elapsedSeconds = elapsedNanoseconds / 1_000_000_000
    let opsPerSecond = Double(iterations) / elapsedSeconds

    print("🔥 \(label) - Time: \(formatNumber( elapsedSeconds)) seconds, Ops/sec: \(formatNumber(opsPerSecond))")
}

public func formatNumber(_ number: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
}

@inline(never)
public func blackhole<T>(_ value: T) {
    _ = value
}
