//
//  add_line_to_buffer.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 3/17/25.
//

public class AddLineToBuffer: Comprehension.Entity {
    private var executionContext: StreamExecutionContext
    let inputStream: String
    let outputStream: String
    
    init(aliasMap: [String: String] = [:], executionContext: StreamExecutionContext) {
        self.executionContext = executionContext
        self.inputStream = aliasMap["input"] ?? "input"
        self.outputStream = aliasMap["output"] ?? "output"
    }
    
    func initialize() {
        executionContext.ensure(outputStream,defaultValue: [])
    }

    func process() -> EntityResult {
        guard let line = try? executionContext[inputStream].get() as? String else {
            executionContext.triggerUnusualEvent(.warning("Nil input received."))
            return .notAvailable
        }
        

        let current = try? executionContext[outputStream].get()

        if var buffer = current as? [String] {
            buffer.append(line)
            executionContext[outputStream] = .success(buffer)
        } else if current == nil {
            executionContext[outputStream] = .success([line])
        } else {
            executionContext.pendingEvent = .warning("Stream '\(outputStream)' is not a [String]. It is: \(type(of: current ?? "nil"))")
        }
        
        return .proceed
    }
    
    func finalize() {}
}
