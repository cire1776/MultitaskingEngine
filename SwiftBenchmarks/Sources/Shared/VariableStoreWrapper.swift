//
//  VariableStoreWrapper.swift
//  
//
//  Created by Eric Russell on 3/4/25.
//

import CVariableStore  // ✅ Import the C module

public final class VariableStoreWrapper: @unchecked Sendable {
    public init() {
        init_variable_store_bridge()
    }

    public func set(_ value: Int) {
        set_variable_bridge(Int32(value))
    }

    public func get() -> Int {
        return Int(get_variable_bridge())
    }
}
