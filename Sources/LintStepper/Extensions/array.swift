//
//  array.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 4/14/25.
//

import MultitaskingEngine

extension Array {
    func rotatedRight(by k: Int=1) -> [Element] {
        guard !isEmpty else { return self }
        let count = k % self.count
        
        let suffixSlice = self[(self.count - count)...]
        let prefixSlice = self[..<(self.count - count)]
        
        return Array(suffixSlice + prefixSlice)
    }
    
    func window(start: Int, length: Int) -> ArraySlice<Element> {
        guard start >= 0, length > 0 else { return [] }
        let end = Swift.min(start + length, self.count)
        return self[start..<end]
    }
}
