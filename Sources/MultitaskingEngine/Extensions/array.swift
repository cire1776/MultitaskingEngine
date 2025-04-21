//
//  array.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 4/20/25.
//

extension Array where Element == LintSpecifier {
    func tagged(for opName: String) -> [LintSpecifier] {
        let id = ULangEntityID(opName)
        return self.map { $0.withULangEntityID(id) }
    }
}
