//
//  split_line_into_words.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 4/6/25.
//

final public class SplitLinesIntoWords: Comprehension.ExecutionEntity {
    private let executionContext: StreamExecutionContext
    private let inputStream: String
    private let outputStream: String

    private var wordBuffer: [String] = []

    public let subscriptions: SubscriptionMask
    public var publishes: SubscriptionMask

    public init(aliasMap: [String: String] = [:], executionContext: StreamExecutionContext, subscriptions: SubscriptionMask, publishes: SubscriptionMask) {
        self.inputStream = aliasMap["input"] ?? "input"
        self.outputStream = aliasMap["output"] ?? "output"
        self.executionContext = executionContext
        self.subscriptions = subscriptions
        self.publishes = publishes
    }

    func initialize() {
        wordBuffer.removeAll()
    }

   public func process() -> EntityResult {
        print("======= SplitLinesIntoWords =======")

        if wordBuffer.isEmpty {
            print("----- Reading line -----")
            guard case let .success(line as String) = executionContext[inputStream] else {
                return .notAvailable
            }
            wordBuffer = line.split(separator: " ").map(String.init)
        }

        guard !wordBuffer.isEmpty else {
            return .notAvailable
        }

        let word = wordBuffer.removeFirst()
        print("emit: \(word): \(wordBuffer.isEmpty ? "proceed" : "pump")")
        executionContext[outputStream] = .success(word)
       return wordBuffer.isEmpty ? .proceed : .pump(self.publishes)
    }
    
    func finalize() {
        while !wordBuffer.isEmpty {
            let word = wordBuffer.removeFirst()
            executionContext[outputStream] = .success(word)
            // NOTE: you might also trigger some manual yield here if necessary
        }
    }
}
