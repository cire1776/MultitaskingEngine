//
//  synchronize.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 3/28/25.
//

public class Synchronize: Comprehension.Entity {
    private let inputStream: String
    private let outputStream: String
    
    private var sourceContext: StreamExecutionContext
    private var destinationContext: StreamExecutionContext
    
    public init(
        aliasMap: [String: String] = [:],
        source: StreamExecutionContext,
        destination: StreamExecutionContext,
    ) {
        self.inputStream = aliasMap["input"] ?? "input"
        self.outputStream = aliasMap["output"] ?? "output"
        
        self.sourceContext = source
        self.destinationContext = destination
    }
    
    public func process() -> EntityResult {
        guard let value = try? sourceContext[inputStream].get() as? [String] else {
            return .notAvailable
        }

        var destinationValue: [String] = []
        
        if destinationContext.containsKey(outputStream) {
            guard let value = try? destinationContext[outputStream].get() as? [String] else {
                return .notAvailable
            }
            destinationValue = value
        }
        
        destinationValue.append(contentsOf: value)
        destinationContext[outputStream] = .success(destinationValue)
        return .proceed
    }
}
