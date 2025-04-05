//
//  SubscriptionStreamExecutionContextTests.swift
//  MultitaskingEngineTests
//
//  Created by Eric Russell on 4/4/25.
//

import Quick
import Nimble
@testable import MultitaskingEngine

final class SubscriptionStreamExecutionContextTests: AsyncSpec {
    override class func spec() {
        describe("Subscriptions") {
            var subscriptions: Subscriptions!

            beforeEach {
                subscriptions = Subscriptions()
            }

            it("initially has no available subscriptions") {
                expect(subscriptions.available).to(equal(0))
            }

            it("publishes a subscription correctly") {
                subscriptions.publish(0x1)
                // With nothing exhausted, available should equal the published mask.
                expect(subscriptions.available).to(equal(0x1))
            }

            it("does not publish a subscription that is exhausted") {
                subscriptions.exhaust(0x1)
                subscriptions.publish(0x1)
                // The bit for 0x1 is exhausted so available should be 0.
                expect(subscriptions.available).to(equal(0))
            }

            it("combines flags from multiple publishes, subtracting exhausted bits") {
                subscriptions.publish(0x3)  // 0x3 = 0b11
                subscriptions.exhaust(0x1)  // Exhaust bit 0x1 = 0b01
                // available should be 0x3 & ~0x1 = 0b11 & 0b10 = 0x2.
                expect(subscriptions.available).to(equal(0x2))
            }

            it("correctly accumulates multiple publishes") {
                subscriptions.publish(0x1)
                subscriptions.publish(0x2)
                // Expecting 0x1 | 0x2 = 0x3.
                expect(subscriptions.available).to(equal(0x3))
            }

            it("updates available correctly after exhausting some bits") {
                subscriptions.publish(0x7)  // 0x7 = 0b111
                subscriptions.exhaust(0x5)  // 0x5 = 0b101
                // available = 0x7 & ~0x5 = 0b111 & 0b010 = 0x2.
                expect(subscriptions.available).to(equal(0x2))
            }

            it("allows re-publishing new bits after exhausting existing ones") {
                subscriptions.publish(0xF)   // 0xF = 0b1111
                subscriptions.exhaust(0x3)     // exhaust 0b0011
                // available = 0xF & ~0x3 = 0b1111 & 0b1100 = 0xC.
                expect(subscriptions.available).to(equal(0xC))
                
                // Publishing a bit already available doesn't change it.
                subscriptions.publish(0x2)
                expect(subscriptions.available).to(equal(0xC))
                
                // Publishing a new bit (0x10) should add it.
                subscriptions.publish(0x10)
                expect(subscriptions.available).to(equal(0xC | 0x10))
            }

            it("retains exhausted bits") {
                subscriptions.exhaust(0xA) // 0xA = 0b1010
                expect(subscriptions.exhausted).to(equal(0xA))
            }
            
            it("removes published flags when unpublish is called") {
                subscriptions.publish(0xF) // Publish bits: 0b1111
                subscriptions.unpublish(0x5) // Unpublish bits: 0b0101
                // Available = published (0xF) minus unpublishing 0x5 => 0xF & ~0x5 = 0b1111 & 0b1010 = 0xA.
                expect(subscriptions.available).to(equal(0xA))
            }

            it("does nothing if unpublishing bits that were not published") {
                subscriptions.publish(0x3) // 0b0011
                subscriptions.unpublish(0x4) // 0b0100 was not published
                expect(subscriptions.available).to(equal(0x3))
            }

            it("removes all published flags when unpublish is called with the same mask") {
                subscriptions.publish(0xFF)
                subscriptions.unpublish(0xFF)
                expect(subscriptions.available).to(equal(0))
            }

            it("does not change exhausted flags when unpublishing") {
                // Publish some bits, then exhaust some of them.
                subscriptions.publish(0xF)         // 0b1111
                subscriptions.exhaust(0x5)           // 0b0101 (exhausted)
                // Before unpublish, available = published & ~exhausted = 0xF & ~0x5 = 0xF & 0xA = 0xA.
                expect(subscriptions.available).to(equal(0xA))
                
                subscriptions.unpublish(0x3)         // Attempt to unpublish 0b0011
                // New available = (0xF & ~0x3) & ~0x5 = (0xC) & ~0x5 = 0xC & 0xA = 0x8.
                expect(subscriptions.available).to(equal(0x8))
            }
        }

        describe("SubscriptionStreamExecutionContext") {
            var executionContext: SubscriptionStreamExecutionContext!
            
            context("with no flags provided") {
                beforeEach {
                    executionContext = SubscriptionStreamExecutionContext()  // defaults to empty dictionary
                }
                
                it("returns 0 for a key with no flag set") {
                    expect(executionContext["nonexistent"]).to(equal(0))
                }
            }
            
            context("with custom flags provided") {
                it("returns the correct flag value for a single key") {
                    let customFlags: [String: UInt32] = ["a": 0x1]
                    executionContext = SubscriptionStreamExecutionContext(streamFlags: customFlags)
                    expect(executionContext["a"]).to(equal(0x1))
                }
                
                it("combines flags from multiple keys using bitwise OR") {
                    let customFlags: [String: UInt32] = ["a": 0x1, "b": 0x2]
                    executionContext = SubscriptionStreamExecutionContext(streamFlags: customFlags)
                    expect(executionContext["a", "b"]).to(equal(0x3))
                }
                
                it("returns the bitwise OR for multiple keys") {
                    let customFlags: [String: UInt32] = ["x": 0x4, "y": 0x8]
                    executionContext = SubscriptionStreamExecutionContext(streamFlags: customFlags)
                    expect(executionContext["x", "y"]).to(equal(0xC))
                }
                
                it("retains flag values after endTick is called") {
                    let customFlags: [String: UInt32] = ["persistent": 0x10]
                    executionContext = SubscriptionStreamExecutionContext(streamFlags: customFlags)
                    executionContext.endTick()
                    expect(executionContext["persistent"]).to(equal(0x10))
                }
            }
        }
    }
}
