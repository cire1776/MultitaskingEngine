//
//  print.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 3/21/25.

public class Print {
    var executionContext: StreamExecutionContext
    let inputStream: String
    // no output
    
    public init(aliasMap: [String: String] = [:], executionContext: StreamExecutionContext) {
        self.executionContext = executionContext
        self.inputStream = aliasMap["input"] ?? "input"
    }
    
    public func process() -> EntityResult {
        if case let .success(output) = executionContext[inputStream] {
            print(output ?? "~nil~")
            return .proceed
        }
        return .notAvailable
    }
}
