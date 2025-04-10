//
//  split_line_into_words.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 4/6/25.
//

final public class SplitLinesIntoWords: Comprehension.Entity {
    private let executionContext: StreamExecutionContext
    private let inputStream: String
    private let outputStream: String

    private var wordBuffer: [String] = []

    public let subscriptions: SubscriptionMask = 0x1

    public init(aliasMap: [String: String] = [:], executionContext: StreamExecutionContext) {
        self.inputStream = aliasMap["input"] ?? "input"
        self.outputStream = aliasMap["output"] ?? "output"
        self.executionContext = executionContext
    }

    func initialize() {
        wordBuffer.removeAll()
    }

    func process(publishes: SubscriptionMask=0) -> EntityResult {
        if wordBuffer.isEmpty {
            guard case let .success(line as String) = executionContext[inputStream] else {
                return .notAvailable
            }
            wordBuffer = line.split(separator: " ").map(String.init)
        }

        guard !wordBuffer.isEmpty else {
            return .notAvailable
        }

        let word = wordBuffer.removeFirst()
        executionContext[outputStream] = .success(word)
        return wordBuffer.isEmpty ? .proceed : .pump(publishes)
    }
    
    func finalize() {
        while !wordBuffer.isEmpty {
            let word = wordBuffer.removeFirst()
            executionContext[outputStream] = .success(word)
            // NOTE: you might also trigger some manual yield here if necessary
        }
    }
}
