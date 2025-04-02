//
//  comprehensions.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 3/31/25.
//

import Foundation

public enum EntityResult: Equatable {
    case proceed
    case notAvailable
    case eof
    case unusualExecutionEvent
}

final class ComprehensionInstance: RunnableLintProvider, CustomStringConvertible {
    let blueprintName: String
    var executionContext: StreamExecutionContext
    private(set) var table: LintTable
    
    public var operationName: String {
        "\(blueprintName)__\(String(format: "%X", UUID().uuidString.hashValue))"
    }
    
    init(blueprint: LintProvider, preinitializationLint: Lint?=nil, executionContext: StreamExecutionContext?=nil) {
        self.blueprintName = blueprint.operationName
        
        self.executionContext = executionContext ?? StreamExecutionContext()

        self.table = blueprint.table
        
        if let preinitializationLint = preinitializationLint {
            self.table.lints.insert(preinitializationLint, at: 0)
        }
    }
    
    public var description: String {
        "ComprehensionInstance for \(blueprintName) with EC: \(executionContext)"
    }
}
