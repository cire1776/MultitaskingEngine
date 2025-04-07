//
//  emit_string.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 4/6/25.
//

final class EmitString: Comprehension.Entity {
    private let executionContext: StreamExecutionContext
    private let inputStream: String
    private let outputStream: String
    private var lines: [String] = []
    private var currentIndex: Int

    let subscriptions: SubscriptionMask = 0

    init(aliasMap: [String: String] = [:], executionContext: StreamExecutionContext) {
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
        guard currentIndex < lines.count else {
            return .eof
        }

        executionContext[outputStream] = .success(lines[currentIndex])
        currentIndex += 1
        return .proceed
    }

    func finalize() {}
}
