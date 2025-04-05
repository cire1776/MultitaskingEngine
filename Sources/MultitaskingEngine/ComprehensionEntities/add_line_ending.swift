//
//  add_line_ending.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 3/16/25.
//

public class AddLineEnding: Comprehension.Entity {
    let inputStream: String
    var executionContext: StreamExecutionContext
    
    public init(aliasMap: [String: String], executionContext: StreamExecutionContext) {
        self.executionContext = executionContext
        self.inputStream = aliasMap["input"] ?? "input"
    }
   
    public func initialize() {  }
    
    public func process() -> EntityResult {
        guard let line = try? executionContext[inputStream].get() as? String else {
            return .notAvailable
        }
        
        if !line.hasSuffix("\n") {
             executionContext[inputStream] = .success(line + "\n")
        }

        return .proceed
    }
}
