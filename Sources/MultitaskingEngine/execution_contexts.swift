import Foundation
import PointerUtilities

/// ✅ Execution Context Error Types
enum ExecutionContextError: Error, Equatable {
    case variableNotFound(String)
    case indexOutOfRange(UInt)
    case invalidVariableType
    case staleEphemeralVariable
}

public typealias StreamSetter = (String, Any?)

enum VariableStorage {
    case value(Any?)
    case ephemeral(Any?, tick: Int)
    case index(Int)
}

public protocol HeapExecutionContext: AnyObject {
    var operation: Operation? { get }
    
    var pendingEvent: UnusualExecutionEvent? { get set }
    var shouldYield: Bool { get set }
    
    func triggerUnusualEvent(_ event: UnusualExecutionEvent)
}

extension HeapExecutionContext {
    public func triggerUnusualEvent(_ event: UnusualExecutionEvent) {
        // Store the event, mark yield requested, etc.
        self.pendingEvent = event
        self.shouldYield = true
    }
}

enum EC {
    protocol Readable where Self: HeapExecutionContext {
        subscript(_ name: String) -> Result<Any?, ExecutionContextError> { get }
        
        func containsKey(_ name: String) -> Bool
    }
    
    protocol Writable: EC.Readable {
        subscript(_ name: String) -> Result<Any?, ExecutionContextError> { get set }
        
        func remove(_ name: String)
    }

    protocol Streaming: EC.Writable {
       var tick: Int { get }

       func ensure(_ name: String, defaultValue: Any?)
        
       func endTick()
    }
}

public class ExecutionContext: HeapExecutionContext, EC.Writable {
    public var operation: Operation? = nil
    
    public var pendingEvent: UnusualExecutionEvent? = nil
    public var shouldYield: Bool = false
    
    private var dynamicVariables: [String: VariableStorage] = [:]
    private let dynamicLock = NSLock()

    subscript(name: String) -> Result<Any?, ExecutionContextError> {
        get {
            dynamicLock.lock()
            defer { dynamicLock.unlock() }

            guard let storage = dynamicVariables[name] else {
                return .success(nil) // ✅ Variable not set yet
            }

            switch storage {
            case let .value(value):
                return .success(value)
            case .index, .ephemeral(_,_):
                return .failure(.invalidVariableType)
            }
        }

        set {
            dynamicLock.lock()
            defer { dynamicLock.unlock() }

            switch newValue {
            case .success(let value):
                // ✅ Store even if value is nil
                dynamicVariables[name] = .value(value)
            case .failure:
                // ✅ Only failure removes the variable
                dynamicVariables.removeValue(forKey: name)
            }
        }
    }
    
    func containsKey(_ name: String) -> Bool {
        dynamicLock.lock()
        defer { dynamicLock.unlock() }
        return dynamicVariables[name] != nil
    }
    
    func remove(_ name: String) {
        dynamicLock.lock()
        defer { dynamicLock.unlock() }
        dynamicVariables.removeValue(forKey: name)
    }
}

public class StreamExecutionContext: HeapExecutionContext, EC.Streaming, @unchecked Sendable {
    public var operation: Operation? = nil
    
    public var pendingEvent: UnusualExecutionEvent?
    public var shouldYield: Bool = false
    
    public private(set) var tick: Int = 1
    
    private var dynamicVariables: [String: VariableStorage] = [:]
    private let dynamicLock = NSLock()
    
    subscript(name: String) -> Result<Any?, ExecutionContextError> {
        get {
            dynamicLock.lock()
            defer { dynamicLock.unlock() }
            
            guard let storage = dynamicVariables[name] else {
                return .success(nil) // ✅ Variable not set yet
            }
            
            switch storage {
            case let .ephemeral(value, storedTick) where storedTick == self.tick:
                return .success(value)
            case .ephemeral(_, _):
                return .failure(.staleEphemeralVariable)
            case let .value(value):
                return .success(value)
            case .index:
                return .failure(.invalidVariableType)
            }
        }
        
        set {
            dynamicLock.lock()
            defer { dynamicLock.unlock() }
            
            switch newValue {
            case .success(let value):
                if let existing = dynamicVariables[name] {
                    switch existing {
                    case .value:
                        dynamicVariables[name] = .value(value)
                        break
                    case .index(_):
                        // currently, index casnnot be written this way.
                        break
                    default:
                        // ✅ Overwrite non-persistent value with new ephemeral
                        dynamicVariables[name] = .ephemeral(value, tick: tick)
                    }
                } else {
                    // ✅ No existing entry—safe to write ephemeral
                    dynamicVariables[name] = .ephemeral(value, tick: tick)
                }
                
            case .failure:
                // ✅ Only remove if it’s not .value
                if let existing = dynamicVariables[name] {
                    switch existing {
                    case .value:
                        // ✅ Keep persistent value untouched
                        break
                    default:
                        // ✅ Remove ephemeral or other dynamic content
                        dynamicVariables.removeValue(forKey: name)
                    }
                }
            }
        }
    }
    
    func containsKey(_ name: String) -> Bool {
        dynamicLock.lock()
        defer { dynamicLock.unlock() }
        return dynamicVariables[name] != nil
    }
    
    func remove(_ name: String) {
        dynamicLock.lock()
        defer { dynamicLock.unlock() }
        dynamicVariables.removeValue(forKey: name)
    }
    
    func ensure(_ name: String, defaultValue: Any?) {
        dynamicLock.lock()
        defer { dynamicLock.unlock() }
        
        guard dynamicVariables[name] == nil else {
            return  // ✅ Don't override existing values
        }
        
        dynamicVariables[name] = .value(defaultValue)
    }
    
    func endTick() {
        self.tick += 1
    }
}

extension StreamExecutionContext {
    /// Returns a formatted string that lists all stored streams.
    public func dumpStreams() -> String {
        var output = "---- Execution Context Dump ----\n"
        dynamicLock.lock()
        let sortedKeys = dynamicVariables.keys.sorted()
        for key in sortedKeys {
            let valueDescription: String
            if let storage = dynamicVariables[key] {
                switch storage {
                case .value(let anyValue):
                    valueDescription = "\(anyValue ?? "nil")"
                case .ephemeral(let anyValue, let tick):
                    valueDescription = "ephemeral(\(anyValue ?? "nil"), tick: \(tick))"
                case .index(let index):
                    valueDescription = "index(\(index))"
                }
            } else {
                valueDescription = "nil"
            }
            output += "  \(key): \(valueDescription)\n"
        }
        dynamicLock.unlock()
        output += "---- End Dump ----\n"
        return output
    }
}
