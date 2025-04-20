//
//  string.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 4/20/25.
//

public extension String {
    /// Deterministic 64-bit FNV-1a hash
    var stableHash64: UInt64 {
        let fnvOffset: UInt64 = 0xcbf29ce484222325
        let fnvPrime: UInt64 = 0x100000001b3

        var hash = fnvOffset
        for byte in self.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* fnvPrime
        }
        return hash
    }
}
