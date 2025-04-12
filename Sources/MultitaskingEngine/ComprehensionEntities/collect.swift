//
//  collect.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 4/7/25.
//

import Foundation

extension Character {
    var isEmoji: Bool {
        return self.unicodeScalars.contains { $0.properties.isEmojiPresentation }
    }
}

public struct Group: Equatable {
    
    public enum Kind {
        case bareword
        case digits
        case whitespace
        case symbol
        case delimiter
    }
    
    public let kind: Kind
    public let value: String
    
    public init(kind: Kind, value: String) {
        self.kind = kind
        self.value = value
    }
    
    // MARK: - Helpers
    
    @inline(__always)
    public var isEmpty: Bool {
        return value.isEmpty
    }
    
    @inline(__always)
    public var count: Int {
        return value.count
    }
    
    static func classify(_ char: Character) -> Kind {
        switch char {
        case _ where char.isWhitespace:
            return .whitespace
        case _ where char.isNumber:
            return .digits
        case _ where char.isLetter || char.isEmoji:
            return .bareword
        default:
            return .symbol
        }
    }
    
    public static func of(_ char: Character) -> Group {
        return Group(kind: classify(char), value: String(char))
    }
}

final public class Collect: Comprehension.ExecutionEntity {
    private let executionContext: StreamExecutionContext
    private let inputStream: String
    private let outputStream: String
    
    private var buffer = ""
    private var bufferKind: Group.Kind? = nil
    private var bufferedGroup: Group?
    
    public let subscriptions: SubscriptionMask
    public var publishes: SubscriptionMask
    
    public init(aliasMap: [String: String] = [:], executionContext: StreamExecutionContext, subscriptions: SubscriptionMask, publishes: SubscriptionMask) {
        self.inputStream = aliasMap["input"] ?? "input"
        self.outputStream = aliasMap["output"] ?? "output"
        self.executionContext = executionContext
        self.subscriptions = subscriptions
        self.publishes = publishes
    }
    
    func initialize() {}
    
   public func process() -> EntityResult {
        print("----- collect -----\n")
        print("collect buffer:\n\(buffer)\n")
        print("collecting: \(String(describing: try? executionContext[inputStream].get()!))")
        
        guard case let .success(nextChar as Character) = executionContext[inputStream] else {
            let wroteBuffer = writeBuffer()
            
            bufferedGroup = try? executionContext[inputStream].get() as? Group
            return wroteBuffer ? .proceed : .notAvailable
        }
        
        let kind = Group.classify(nextChar)
        
        if let currentKind = bufferKind, currentKind == kind {
            buffer.append(nextChar)
        } else {
            // Flush previous buffer
            let wroteBuffer = writeBuffer()
            startBuffer(char: nextChar, kind: kind)
            if wroteBuffer { return .proceed }
        }
        
        return .notAvailable
    }
    
    func drain(publishes: SubscriptionMask=0) -> EntityResult {
        if buffer.isEmpty && bufferedGroup == nil { return .eof }
        _ = writeBuffer()
        return .proceed
    }
    
    private func writeBuffer() -> Bool {
        if let group = bufferedGroup {
            executionContext[outputStream] = .success(group)
            bufferedGroup = nil
            return true
        }
        
        if buffer.isEmpty { return false }
        
        executionContext[outputStream] = .success(Group(kind: bufferKind!, value: buffer))
        print("emit: \(Group(kind: bufferKind!, value: buffer))\n")
        buffer = ""
        bufferKind = nil
        return true
    }
    
    private func startBuffer(char: Character, kind: Group.Kind) {
        buffer = String(char)
        bufferKind = kind
    }
}
