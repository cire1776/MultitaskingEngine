
//
//  collect_strings.swift
//  MultitaskingEngine
//
//  This entity collects a stream of string elements and accumulates them into a single array output.
//

import Foundation

final class CollectStrings: Comprehension.Entity {
    private let executionContext: StreamExecutionContext
    private let inputStream: String
    private let outputStream: String
    private var buffer: [String] = []

    let subscriptions: SubscriptionMask = 0

    init(aliasMap: [String: String] = [:], executionContext: StreamExecutionContext) {
        self.inputStream = aliasMap["input"] ?? "input"
        self.outputStream = aliasMap["output"] ?? "output"
        self.executionContext = executionContext
    }

    func initialize() {
        buffer = []
    }

    func process(publishes: SubscriptionMask=0) -> EntityResult {
        print("===== CollectStrings =====")
        guard let value = try? executionContext[inputStream].get() else {
            return .notAvailable
        }

        if let string = value as? String {
            print("----- adding string: \(string) ----")
            buffer.append(string)
        } else {
            if let character = value as? Character {
                print("----- adding character: \(character) ----")
                buffer.append(String(character))
            } else {
                return .notAvailable
            }
        }

        return .notAvailable
    }

    func drain(publishes: SubscriptionMask=0) -> EntityResult {
        if buffer.isEmpty { return .notAvailable }

        print("===== CollectStrings =====")
        print("----- draining ----")
        executionContext[outputStream] = .success(buffer)
        buffer.removeAll()
        return .proceed
    }
}
