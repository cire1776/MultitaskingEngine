//
//  PriorityQueueTests.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 3/9/25.
//

import Foundation
import Quick
import Nimble
@testable import MultitaskingEngine

class PriorityQueueSpec: AsyncSpec {
    override class func spec() {
        describe("PriorityQueue") {
            var pq: PriorityQueue<Int>!

            beforeEach {
                pq = PriorityQueue()
            }

            context("when initialized") {
                it("is empty") {
                    let isEmpty = await pq.isEmpty
                    let count = await pq.count

                    expect(isEmpty).to(beTrue())
                    expect(count).to(equal(0))
                }
            }

            context("pushing and popping elements") {
                it("maintains the correct order") {
                    await pq.push(3)
                    await pq.push(1)
                    await pq.push(4)
                    await pq.push(2)

                    let first = await pq.popMin()
                    let second = await pq.popMin()
                    let third = await pq.popMin()
                    let fourth = await pq.popMin()
                    let isEmpty = await pq.isEmpty

                    expect(first).to(equal(1))
                    expect(second).to(equal(2))
                    expect(third).to(equal(3))
                    expect(fourth).to(equal(4))
                    expect(isEmpty).to(beTrue())
                }
            }

            context("peekMin functionality") {
                it("returns the smallest element without removing it") {
                    await pq.push(5)
                    await pq.push(2)
                    await pq.push(8)

                    let min = await pq.peekMin()
                    let count = await pq.count

                    expect(min).to(equal(2))
                    expect(count).to(equal(3)) // Ensure size remains unchanged
                }
            }

            context("popping from an empty queue") {
                it("returns nil") {
                    let result = await pq.popMin()
                    expect(result).to(beNil())
                }
            }

            context("handling duplicate values") {
                it("processes them in correct order") {
                    await pq.push(4)
                    await pq.push(4)
                    await pq.push(4)

                    let first = await pq.popMin()
                    let second = await pq.popMin()
                    let third = await pq.popMin()
                    let isEmpty = await pq.isEmpty

                    expect(first).to(equal(4))
                    expect(second).to(equal(4))
                    expect(third).to(equal(4))
                    expect(isEmpty).to(beTrue())
                }
            }

            context("large input handling") {
                it("correctly processes 1000 elements") {
                    let values = (1...1000).shuffled()
                    for value in values {
                        await pq.push(value)
                    }

                    for expected in 1...1000 {
                        let popped = await pq.popMin()
                        expect(popped).to(equal(expected))
                    }

                    let isEmpty = await pq.isEmpty
                    expect(isEmpty).to(beTrue())
                }

                it("should process 100,000 logs in correct order under heavy load") {
                    let totalLogs = 100_000
                    let pq = PriorityQueue<LogEntry>()

                    await withTaskGroup(of: Void.self) { group in
                        for i in 1...totalLogs {
                            group.addTask { @Sendable in
                                let log = LogEntryFactory.create(level: .info, message: "Test Log \(i)")
                                await pq.push(log)  // ✅ Actor-safe push
                            }
                        }

                        // ✅ Ensure all tasks finish before checking PQ count
                        await group.waitForAll()
                    }

                    // ✅ Ensure all logs are enqueued **after tasks complete**
                    let pqCount = await pq.count
                    expect(pqCount).to(equal(totalLogs), description: "PQ should contain exactly \(totalLogs) logs.")

                    var lastDate: UInt64 = 0
                    var processedLogs = 0

                    // ✅ Pop logs and verify order
                    while let log = await pq.popMin() {
                        processedLogs += 1
                        expect(log.timestamp.preciseRelativeTimestamp).to(beGreaterThanOrEqualTo(lastDate), description: "Logs should be dequeued in chronological order!")
                        lastDate = log.timestamp.preciseRelativeTimestamp
                    }

                    // ✅ Ensure all logs were processed
                    let isPQEmpty = await pq.isEmpty
                    expect(processedLogs).to(equal(totalLogs), description: "All logs should be processed correctly.")
                    expect(isPQEmpty).to(beTrue(), description: "Priority queue should be empty after processing all logs.")
                }

                context("alternate push and pop operations") {
                    it("handles interleaved operations correctly") {
                        await pq.push(5)
                        let first = await pq.popMin()
                        await pq.push(3)
                        let second = await pq.popMin()
                        await pq.push(7)
                        let third = await pq.popMin()
                        let isEmpty = await pq.isEmpty

                        expect(first).to(equal(5))
                        expect(second).to(equal(3))
                        expect(third).to(equal(7))
                        expect(isEmpty).to(beTrue())
                    }
                }

                context("mixed operations") {
                    it("maintains correct ordering") {
                        await pq.push(10)
                        await pq.push(1)

                        let first = await pq.popMin()
                        await pq.push(5)
                        let peeked = await pq.peekMin()
                        await pq.push(3)
                        let second = await pq.popMin()
                        let third = await pq.popMin()
                        let fourth = await pq.popMin()
                        let isEmpty = await pq.isEmpty

                        expect(first).to(equal(1))
                        expect(peeked).to(equal(5))
                        expect(second).to(equal(3))
                        expect(third).to(equal(5))
                        expect(fourth).to(equal(10))
                        expect(isEmpty).to(beTrue())
                    }
                }
            }
        }
    }
}
