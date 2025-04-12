//
//  synchronize.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 3/28/25.
//

public class Synchronize: Comprehension.ExecutionEntity {
    private let inputStream: String
    private let outputStream: String

    private var sourceContext: StreamExecutionContext
    private var destinationContext: StreamExecutionContext

    public var subscriptions: SubscriptionMask
    public var publishes: SubscriptionMask

    public init(
        aliasMap: [String: String] = [:],
        source: StreamExecutionContext,
        destination: StreamExecutionContext,
        subscriptions: SubscriptionMask,
        publishes: SubscriptionMask
    ) {
        self.inputStream = aliasMap["input"] ?? "input"
        self.outputStream = aliasMap["output"] ?? "output"

        self.sourceContext = source
        self.destinationContext = destination

        self.subscriptions = subscriptions
        self.publishes = publishes
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
