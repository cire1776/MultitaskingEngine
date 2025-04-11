//
//  detect_delimiter.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 4/8/25.
//

enum DelimiterRole {
    case opener
    case closer
    case both
}

final class DelimiterTrie {
    struct Node {
        let isTerminal: Bool
        let role: DelimiterRole?
        let children: [Character: Node]
        
        func advance(with char: Character) -> Node? {
            return children[char]
        }
    }
    
    /// Root node — statically built
    static let root: Node = {
        func n(_ t: Bool = false, _ r: DelimiterRole? = nil, _ c: [Character: Node] = [:]) -> Node {
            return Node(isTerminal: t, role: r, children: c)
        }
        
        return n(false, nil, [
            "/": n(false, nil, [
                "*": n(true, .opener),                // "/*"
                "/": n(true, .opener),                // "//"
                "!": n(true, .opener),                // "/!"
                "?": n(true, .opener),                // "/?"
                "#": n(true, .opener),                // "/#"
                "@": n(true, .opener)                 // "/@"
            ]),
            "*": n(false, nil, [
                "/": n(true, .closer)                 // "*/"
            ]),
            "<": n(false, nil, [
                "<": n(true, .opener, [
                    "d": n(false, nil, [
                        "o": n(false, nil, [
                            "c": n(true, .opener)    // "<<doc"
                        ])
                    ])
                ])
            ]),
            ">": n(false, nil, [
                ">": n(true, .closer)                 // ">>"
            ]),
            "{": n(false, nil, [
                "{": n(true, .opener)                 // "{{"
            ]),
            "}": n(false, nil, [
                "}": n(true, .closer)                 // "}}"
            ]),
            "~": n(false, nil, [
                "~": n(true, .both)                   // "~~"
            ]),
            "#": n(false, nil, [
                ">": n(true, .closer)                 // "#>"
            ]),
            "!": n(false, nil, [
                "*": n(true, .opener)                 // "/*!"
            ])
        ])
    }()
    
    struct MatchResult {
        let matched: String?         // e.g. "<<doc"
        let endIndex: Int            // index after last matched character
        let isPartial: Bool          // true if it's a prefix but not a full match
        let role: DelimiterRole?     // .opener, .closer, .both
    }
}

final public class DelimiterCursor {
    private var node: DelimiterTrie.Node
    private var buffer: String
    private var matched: String?
    private var role: DelimiterRole?
    
    init() {
        self.node = DelimiterTrie.root
        self.buffer = ""
    }
    
    func feed(_ char: Character) -> DelimiterTrie.MatchResult {
        guard let next = node.advance(with: char) else {
            return DelimiterTrie.MatchResult(
                matched: matched,
                endIndex: buffer.count,
                isPartial: matched == nil && !buffer.isEmpty,
                role: role
            )
        }
        
        buffer.append(char)
        node = next
        
        if node.isTerminal {
            matched = buffer
            role = node.role
        }
        
        return DelimiterTrie.MatchResult(
            matched: matched,
            endIndex: buffer.count,
            isPartial: matched == nil,
            role: role
        )
    }
    
    func reset() {
        node = DelimiterTrie.root
        buffer = ""
        matched = nil
        role = nil
    }
    
    var isComplete: Bool {
        return matched != nil
    }
    
    var current: String {
        return buffer
    }
    
    var isAtStart: Bool {
        return buffer.isEmpty
    }
    
    var isDeadEnd: Bool {
        return node.children.isEmpty
    }
    
    var isPartial: Bool {
        return !buffer.isEmpty
        
    }
}

final public class DetectDelimiter: Comprehension.Entity {
    private var executionContext: StreamExecutionContext!
    
    private var inputSubscription: SubscriptionMask = 0x1
    private let stream: String
    // ouputs to input stream
    
    public var subscriptions: SubscriptionMask = 0x1
    
    private var cursor = DelimiterCursor()
    private var bufferIndex = "".startIndex
    private var bufferedInput: Any?
    
    let simpleDelimiters: Set<String> = [
        "\"", "'", "`", "`",           // collapsing delimiters
        "(", ")", "{", "}", "[", "]"   // scoping delimiters
    ]
    
    public init(aliasMap: [String: String] = [:], executionContext: StreamExecutionContext) {
        self.executionContext = executionContext
        self.stream = aliasMap["input"] ?? "input"
    }
    
    func process() -> EntityResult {
        print("---- DetectDelimiter ----")
        guard let rawInput = try? executionContext[stream].get(),
              let input = rawInput as? Group,
              input.kind == .symbol
        else {
            let wroteBuffer = drainBuffer()
            return wroteBuffer ?? .proceed
        }
        
        if  cursor.isAtStart,
            simpleDelimiters.contains(String(input.value)) {
            executionContext[stream] = .success(Group(kind: .delimiter, value: input.value))
            print("Detected simple delimiter: \(input.value)")
            return .proceed
        }
        
        let result = cursor.feed(Character(input.value))
        
        if let full = result.matched {
            executionContext[stream] = .success(Group(kind: .delimiter, value: full))
            cursor.reset()
            return .proceed
        }
        
        if cursor.isDeadEnd {
            return drainBuffer() ?? .notAvailable
        }
        
        return cursor.isPartial ? .notAvailable : .proceed
    }
    
    func drain() -> EntityResult {
        return drainBuffer() ?? .notAvailable
    }
    
    private func drainBuffer() -> EntityResult? {
        if  bufferIndex >= cursor.current.endIndex,
            bufferedInput == nil
            { return nil }
        
        if let priorInput = bufferedInput {
            executionContext[stream] = .success(priorInput)
            return .proceed
        }
        
        if let input = try? executionContext[stream].get() {
            bufferedInput = input
        }
        
        executionContext[stream] = .success(Group(kind: .symbol, value: cursor.current))
        cursor.reset()
        
        return bufferedInput == nil ? .proceed : .pump(0x01)
     }
}

