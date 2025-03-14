//
//  ConcurrentQueueTests.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 3/9/25.
//

import Foundation
import Network
import Quick
import Nimble
@testable import MultitaskingEngine

// ✅ Unit Tests using Quick/Nimble
class QueueTests: AsyncSpec {
    override class func spec() {
        describe("ConcurrentQueue") {
            var queue: ConcurrentQueue<String>!
            
            beforeEach {
                queue = ConcurrentQueue<String>()
            }
            
            it("should enqueue and dequeue correctly") {
                queue.enqueue("Test Message")
                expect(queue.isEmpty).to(beFalse())
                expect(queue.dequeue()).to(equal("Test Message"))
                expect(queue.isEmpty).to(beTrue())
            }
        }
        
        describe("InputQueue and OutputQueue") {
            var sharedQueue: ConcurrentQueue<String>!
            var inputQueue: InputQueue!
            var outputQueue: OutputQueue!
            let testConfig = PortConfiguration(host: "127.0.0.1", port: 8081)
            
            beforeEach {
                sharedQueue = ConcurrentQueue<String>()
                inputQueue = InputQueue(config: testConfig, queue: sharedQueue)
                outputQueue = OutputQueue(config: testConfig, queue: sharedQueue)
            }
            
            it("should receive and enqueue messages") {
                inputQueue.queue.enqueue("Hello")
                expect(sharedQueue.isEmpty).to(beFalse())
                expect(sharedQueue.dequeue()).to(equal("Hello"))
            }
            
            it("should dequeue and process messages") {
                sharedQueue.enqueue("Send This")
                expect(outputQueue.process()).to(equal(.proceed))
            }
        }
    }
}
