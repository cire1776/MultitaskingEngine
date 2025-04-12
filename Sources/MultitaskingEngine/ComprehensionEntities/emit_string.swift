//
//  emit_string.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 4/6/25.
//

final public class EmitString: Comprehension.DataSourceEntity {
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
            lines = string.components(separatedBy: "\n")
        case let array as [String]:
            lines = array
        default:
            lines = []
        }
    }

    public func next() -> EntityResult {
        print("====== emit string =======")
        guard currentIndex < lines.count else {
            print("---- eof ----")
            return .eof
        }

        executionContext[outputStream] = .success(lines[currentIndex])
        print("emit line: \(lines[currentIndex])")
        currentIndex += 1
        return .proceed
    }
}
