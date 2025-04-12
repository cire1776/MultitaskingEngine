//
//  emit_string_with_returns.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 4/9/25.
//

final public class EmitStringWithReturns: Comprehension.Entity {
    private let executionContext: StreamExecutionContext
    private let inputStream: String
    private let outputStream: String
    private var lines: [String] = []
    private var currentIndex: Int

    public let subscriptions: SubscriptionMask
    public var publishes: SubscriptionMask
    
    public init(aliasMap: [String: String] = [:], executionContext: StreamExecutionContext, subscriptions: SubscriptionMask, publishes: SubscriptionMask) {
        self.executionContext = executionContext
        self.inputStream = aliasMap["input"] ?? "input"
        self.outputStream = aliasMap["output"] ?? "output"
        self.subscriptions = subscriptions
        self.publishes = publishes

                
        currentIndex = 0
    }

    func initialize() {
        switch try? executionContext[inputStream].get()! {
        case let string as String:
            var buffer = ""

            for char in string {
                buffer.append(char)
                if char == "\n" {
                    lines.append(buffer)
                    buffer = ""
                }
            }
            if !buffer.isEmpty {
                lines.append(buffer) // capture last line if no trailing newline
            }
        case let array as [String]:
            lines = array
        default:
            lines = []
        }
    }

    public func next() -> EntityResult {
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
