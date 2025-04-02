//
//  reroute.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 3/15/25.
//


class RerouteEntity {
    private var aliasMap: [String: String]

    let inputStream: String
    let outputStream: String
    var executionContext: StreamExecutionContext

    init(aliasMap: [String: String], executionContext: StreamExecutionContext) {
        self.aliasMap = aliasMap
        self.inputStream = aliasMap["input"] ?? "input"
        self.outputStream = aliasMap["output"] ?? "output"
        self.executionContext = executionContext
    }
    
    public func initialize() {
        if !executionContext.containsKey(inputStream) {
            executionContext.triggerUnusualEvent(.exception("Missing input stream '\(inputStream)' in execution context."))
            return
        }
    }
    
    
    func process() -> EntityResult {
        if case let .success(value) = executionContext[inputStream] {
            executionContext[outputStream] = .success(value)
            executionContext.remove(inputStream)
            return .proceed
        }
        return .notAvailable
    }
    
    public func finalize() {
        
    }

}
