//
//  LintHelpers.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 4/2/25.
//

@testable import MultitaskingEngine

class DummyLintProvider: RunnableLintProvider {
    var table: LintTable.Steppable = LintTable.Sequential(lints: [])
    var operationName: String
    
    init(table: LintTable.Steppable, operationName: String?=nil) {
        self.table = table
        self.operationName = operationName ?? "DummyOperation"
    }
}
