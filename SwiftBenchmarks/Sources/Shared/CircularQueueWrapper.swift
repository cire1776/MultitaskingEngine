//
//  CircularQueueWrapper.swift
//  SwiftBenchmarks
//
//  Created by Eric Russell on 3/3/25.
//

import CQueue  // ✅ Import the C module

public final class CircularQueueWrapper: @unchecked Sendable {
    public init() {
        initQueueBridge()
    }

    public func enqueue(_ value: Int) -> Bool {
        return enqueueBridge(Int32(value))
    }

    public func dequeue() -> Int? {
        var value: Int32 = 0
        return dequeueBridge(&value) ? Int(value) : nil
    }
}
