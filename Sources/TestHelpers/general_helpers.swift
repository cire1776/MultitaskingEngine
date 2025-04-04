//
//  general_helpers.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 2/28/25.
//
import Foundation

func waitForCondition(_ condition: @escaping () -> Bool, timeout: TimeInterval = 0.5, interval: TimeInterval = 0.01) async {
    let maxRetries = Int(timeout / interval)

    for _ in 0..<maxRetries {
        if condition() { return }  // ✅ Exit early if condition is met
        try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
    }

    print("⚠️ Timeout reached waiting for condition.")
}


