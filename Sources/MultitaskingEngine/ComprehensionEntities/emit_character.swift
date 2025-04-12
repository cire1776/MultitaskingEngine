//
//  EmitCharacter.swift
//  MultitaskingEngine
//
//  Created by ChatGPT & Eric on 4/6/25.
//

import Foundation

final public class EmitCharacter: Comprehension.ExecutionEntity {
    private let executionContext: StreamExecutionContext
    private let inputStream: String
    private let outputStream: String

    private var buffer: String = ""
    private var index: String.Index = "".startIndex

    public let subscriptions: SubscriptionMask
    public var publishes: SubscriptionMask

    public init(aliasMap: [String: String] = [:], executionContext: StreamExecutionContext, subscriptions: SubscriptionMask, publishes: SubscriptionMask) {
        self.executionContext = executionContext
        self.inputStream = aliasMap["input"] ?? "input"
        self.outputStream = aliasMap["output"] ?? "output"
        self.subscriptions = subscriptions
        self.publishes = publishes

    }

    func initialize() {
        buffer = ""
        index = buffer.startIndex
    }

   public func process() -> EntityResult {
        print("----emit character----")
        // Only refill if we've exhausted the buffer
        if index >= buffer.endIndex {
            print("loading line")
            switch executionContext[inputStream] {
            case let .success(nextLine as String):
                buffer = nextLine
                index = buffer.startIndex
            case .failure, .success:
                return .notAvailable
            }
        }

        guard index < buffer.endIndex else {
            return .notAvailable
        }

        let character = buffer[index]
        index = buffer.index(after: index)

        executionContext[outputStream] = .success(character)
        print("emitted: \(character)")
        return index < buffer.endIndex ? .pump(self.publishes) : .proceed
    }

    func finalize() {
        // no-op for now
    }
}
