import Foundation
import PointerUtilities

/// ✅ Execution Context Error Types
enum ExecutionContextError: Error, Equatable {
    case variableNotFound(String)
    case indexOutOfRange(UInt)
    case invalidVariableType
}

public typealias StreamSetter = (String, Any?)

public enum EntityResult: Equatable {
    case proceed
    case notAvailable
    case eof
    case warning(String)
    case exception(String)
    case abort(String)
}

enum VariableStorage {
    case value(Any?)   // ✅ Supports `nil` naturally
    case index(Int)    // ✅ References an index in `variables`
}

/// ✅ Read-Only Execution Context Protocol (REC)
protocol ReadExecutionContext {
    subscript(index: UInt) -> Result<Any?, ExecutionContextError> { get }
    subscript(name: String) -> Result<Any?, ExecutionContextError> { get }
    
    func containsKey(_ key: String) -> Bool
}

/// ✅ Execution Context Protocol (EC)
protocol ExecutionContext: ReadExecutionContext {
    init()
    subscript(index: UInt) -> Result<Any?, ExecutionContextError> { get set }
    subscript(name: String) -> Result<Any?, ExecutionContextError> { get set }
    func reset()
    
    func setStream(setter: StreamSetter)
    func setStream(setters: [StreamSetter])

    func triggerUnusualEvent(_ event: UnusualExecutionEvent)
}

/// ✅ Execution Context Manager Protocol
protocol ExecutionContextManaging {
    associatedtype ECType: ExecutionContext

    static var contextTable: [UnsafeRawPointer: ECType] { get set }
    static var lock: APMLock { get }
    static var activeContext: UnsafeRawPointer? { get set }

    @inline(__always) static func registerContext(for object: AnyObject)
    @inline(__always) static func setActiveContext(for object: AnyObject)
    static var current: ECType? { get }
}

extension ExecutionContextManaging {
    @inline(__always)
    static func registerContext(for object: AnyObject) {
        let objectPtr = Unmanaged.passUnretained(object).toOpaque()
        let newContext = ECType()
        
        lock.lock()
        contextTable[objectPtr] = newContext
        lock.unlock()
        
        setActiveContext(with: objectPtr)
    }

    @inline(__always)
    static func setActiveContext(with objectPtr: UnsafeRawPointer) {
        lock.lock()
        activeContext = objectPtr
        lock.unlock()
    }
    
    @inline(__always)
    static func setActiveContext(for object: AnyObject) {
        setActiveContext(with: Unmanaged.passUnretained(object).toOpaque())
    }
    
    @inline(__always)
    static var current: ECType? {
        lock.lock()
        defer { lock.unlock() }
        return activeContext.flatMap { contextTable[$0] }
    }
}

final class ThreadExecutionContext: ExecutionContext, ExecutionContextManaging, @unchecked Sendable {
    typealias ECType = ThreadExecutionContext
    
    nonisolated(unsafe) static var contextTable: [UnsafeRawPointer: ThreadExecutionContext] = [:]
    nonisolated(unsafe) static let lock = APMLock()
    nonisolated(unsafe) static var activeContext: UnsafeRawPointer?

    private let bufferLock = APMLock()
    private let dynamicLock = APMLock()
    var dynamicVariables: [String: VariableStorage] = [:]
    var variables: [UnsafeRawPointer?]

    private let uuesHandler: any UUESHandling
    
    required init() {
        self.variables = Array(repeating: nil, count: 1000)
        self.uuesHandler = DefaultUUESHandler()
    }
    
    required init(uuesHandler: UUESHandling? = nil) {
        self.variables = Array(repeating: nil, count: 1000)
        self.uuesHandler = uuesHandler ?? DefaultUUESHandler()
    }

    public func containsKey(_ key: String) -> Bool {
        dynamicLock.lock()
        defer { dynamicLock.unlock() }
        return dynamicVariables[key] != nil // allegedly faster than containsKey
    }
    
    subscript(index: UInt) -> Result<Any?, ExecutionContextError> {
        get {
               bufferLock.lock()
               defer { bufferLock.unlock() }

               guard index < variables.count else {
                   return .failure(.indexOutOfRange(index))
               }

               if let rawPointer = variables[Int(index)] {
                   // ✅ Safely retrieve the object using Unmanaged
                   let object = Unmanaged<AnyObject>.fromOpaque(rawPointer).takeUnretainedValue()
                   return .success(object)
               }

               return .success(nil) // ✅ Properly handle `nil` cases
           }
        set(newValue) {
            bufferLock.lock()
            defer { bufferLock.unlock() }
            
            guard index < variables.count else { return }
            
            if let value = try? newValue.get() {
                variables[Int(index)] = UnsafeRawPointer(Unmanaged.passUnretained(value as AnyObject).toOpaque())
            } else {
                variables[Int(index)] = nil
            }
        }
    }

    subscript(name: String) -> Result<Any?, ExecutionContextError> {
        get {
            dynamicLock.lock()
            defer { dynamicLock.unlock() }
            
            if let stored = dynamicVariables[name] {
                switch stored {
                case .value(let value):
                    return .success(value) // ✅ Now correctly supports `nil`
                case .index(let i):
                    return variables.indices.contains(i)
                        ? .success(variables[i])
                    : .failure(.indexOutOfRange(UInt(i)))
                }
            }

            if let value = dynamicVariables[name] {
                return .success(value)
            }

            return .failure(.variableNotFound(name))
        }
        set {
            dynamicLock.lock()
            defer { dynamicLock.unlock() }

            do {
                let value = try newValue.get()
                dynamicVariables[name] = .value(value) // ✅ Ensures `nil` is stored, not removed
            } catch {
                dynamicVariables.removeValue(forKey: name) // ✅ Only removes when explicitly invalid
            }
        }
    }
    
    func reset() {
        bufferLock.lock()
        dynamicLock.lock()
        defer {
            bufferLock.unlock()
            dynamicLock.unlock()
        }
        dynamicVariables.removeAll()
        variables = Array(repeating: nil, count: variables.count)
    }
    
    func setStream(setter: StreamSetter) {
        self[setter.0] = .success(setter.1)
    }
    
    func setStream(setters: [StreamSetter]) {
        for setter in setters {
            self[setter.0] = .success(setter.1)
        }
    }

    func triggerUnusualEvent(_ event: UnusualExecutionEvent) {
        print("🔥 UUES Triggered: \(event)")
        uuesHandler.handleUnusualEvent(event)
    }
}
