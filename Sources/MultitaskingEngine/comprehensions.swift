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
public enum Comprehension {
    protocol Common: AnyObject, LintProvider {
        var executionContext: StreamExecutionContext { get }
        var table: LintTable.Steppable { get }
        
        var operationID: Int           { get }
        var operationName: String      { get }
        
        func instantiate(preinitialization_lint: Lint?, executionContext: StreamExecutionContext?) -> Instance
    }
    
    protocol Standard: Common {  }
    
    final class Instance: RunnableLintProvider {
        let blueprintName: String
        var executionContext: StreamExecutionContext
        private(set) var table: LintTable.Steppable
        
        public var operationName: String {
            "\(blueprintName)__\(String(format: "%X", UUID().uuidString.hashValue))"
        }
        
        init(blueprint: Common, preinitializationLint: Lint?=nil, executionContext: StreamExecutionContext?=nil) {
            self.blueprintName = blueprint.operationName
            
            self.executionContext = executionContext ?? blueprint.executionContext

            self.table = blueprint.table
            
            if let preinitializationLint = preinitializationLint {
                self.table.prepend(preinitializationLint)
            }
        }
    }
    
}

extension Comprehension.Standard {
    public var operationName: String {
        "Comprehension_\(String(format: "%X",operationID))"
    }
}
