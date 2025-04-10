//
//  emit_string.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 4/6/25.
//

final public class EmitString: Comprehension.Entity {
    private let executionContext: StreamExecutionContext
    private let inputStream: String
    private let outputStream: String
    private var lines: [String] = []
    private var currentIndex: Int

    public let subscriptions: SubscriptionMask = 0

    public init(aliasMap: [String: String] = [:], executionContext: StreamExecutionContext) {
        self.executionContext = executionContext
        self.inputStream = aliasMap["input"] ?? "input"
        self.outputStream = aliasMap["output"] ?? "output"
                
        currentIndex = 0
    }

    func initialize() {
        switch try? executionContext[inputStream].get()! {
        case let string as String:
            lines = string.components(separatedBy: "\n")
        case let array as [String]:
            lines = array
        default:
            lines = []
        }
    }

    func next() -> EntityResult {
        print("---- emit_string.next ----")
        guard currentIndex < lines.count else {
            return .eof
        }

        executionContext[outputStream] = .success(lines[currentIndex])
        print("emit line: \(lines[currentIndex])")
        currentIndex += 1
        return .proceed
    }
}
