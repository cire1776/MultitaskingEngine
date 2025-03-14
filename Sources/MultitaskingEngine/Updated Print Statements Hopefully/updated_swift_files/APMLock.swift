//
//  APMLock.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 3/7/25.
//

/*
 - Do we add a tryLock() method for non-blocking locking?
 - Should we allow a runtime option to choose SpinLock, AtomicLock, or MutexLock dynamically?
 - Do we expose a LockMode enum to allow different locking strategies in different execution contexts?
*/

#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
import Foundation
import Darwin
#else
import Glibc
#endif

/// ✅ Cross-Platform Adaptive Lock
final class APMLock {
    #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
    private let _lock = NSLock()
    #else
    private var _lock = pthread_mutex_t()
    #endif

    init() {
        #if !os(macOS) && !os(iOS) && !os(tvOS) && !os(watchOS)
        pthread_mutex_init(&_lock, nil)
        #endif
    }

    /// ✅ Locks the execution context
    func lock() {
        #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
        _lock.lock()
        #else
        pthread_mutex_lock(&_lock)
        #endif
    }

    /// ✅ Unlocks the execution context
    func unlock() {
        #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
        _lock.unlock()
        #else
        pthread_mutex_unlock(&_lock)
        #endif
    }

    /// ✅ Attempts to lock the execution context without blocking
    /// - Returns: `true` if the lock was acquired, `false` otherwise
    func tryLock() -> Bool {
        #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
        return _lock.try()
        #else
        return pthread_mutex_trylock(&_lock) == 0
        #endif
    }

    /// ✅ Executes a closure while holding the lock
    /// - Parameter closure: The closure to execute
    /// - Returns: The result of the closure
    func withLock<T>(_ closure: () throws -> T) rethrows -> T {
        lock()
        defer { unlock() }
        return try closure()
    }

    deinit {
        #if !os(macOS) && !os(iOS) && !os(tvOS) && !os(watchOS)
        pthread_mutex_destroy(&_lock)
        #endif
    }
}
