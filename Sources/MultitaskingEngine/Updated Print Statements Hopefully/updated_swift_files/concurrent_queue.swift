//
//  concurrent_queue.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 3/9/25.
//

import Foundation
import Network

// MARK: - Configuration Struct
struct PortConfiguration {
    let host: String
    let port: UInt16
}

// ✅ Thread-safe queue implementation (concurrency-safe)
final class ConcurrentQueue<T> {
    private var queue: [T] = []
    private let lock = NSLock()

    func enqueue(_ element: T) {
        lock.lock()
        defer { lock.unlock() }
        queue.append(element)
    }

    func dequeue() -> T? {
        lock.lock()
        defer { lock.unlock() }
        return queue.isEmpty ? nil : queue.removeFirst()
    }

    var isEmpty: Bool {
        lock.lock()
        defer { lock.unlock() }
        return queue.isEmpty
    }
}

// ✅ InputQueue Entity
final class InputQueue: @unchecked Sendable {
    private let config: PortConfiguration
    public let queue: ConcurrentQueue<String>

    private var listener: NWListener?

    init(config: PortConfiguration, queue: ConcurrentQueue<String>) {
        self.config = config
        self.queue = queue
    }

    func initialize() {
        do {
            listener = try NWListener(using: .tcp, on: NWEndpoint.Port(integerLiteral: config.port))
            listener?.newConnectionHandler = { [weak self] connection in
                self?.handleConnection(connection)
            }
            listener?.start(queue: .global())
        } catch {
            logger.log(level: LogLevel.error, message: "Listener initialization failed: \(error)")
        }
    }

    private func handleConnection(_ connection: NWConnection) {
        connection.start(queue: .global())
        connection.receive(minimumIncompleteLength: 1, maximumLength: 4096) { [weak self] data, _, _, _ in
            if let data = data, let message = String(data: data, encoding: .utf8) {
                self?.queue.enqueue(message)
            }
        }
    }

    func next() -> EntityResult {
        return .proceed
    }

    func finalize() {
        listener?.cancel()
    }
}

// ✅ OutputQueue Entity
final class OutputQueue {
    private let config: PortConfiguration
    private let queue: ConcurrentQueue<String>

    init(config: PortConfiguration, queue: ConcurrentQueue<String>) {
        self.config = config
        self.queue = queue
    }

    func initialize() {}

    func process() -> EntityResult {
        guard let message = queue.dequeue() else {
            return .notAvailable
        }

        let connection = NWConnection(host: NWEndpoint.Host(config.host), port: NWEndpoint.Port(integerLiteral: config.port), using: .tcp)

        connection.stateUpdateHandler = { state in
            if case .ready = state {
                connection.send(content: message.data(using: .utf8), completion: .contentProcessed({ _ in }))
            }
        }

        connection.start(queue: .global())
        return .proceed
    }

    func finalize() {}
}
