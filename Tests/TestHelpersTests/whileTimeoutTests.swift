//
//  whileTimeoutTests.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 3/8/25.
//

import Foundation
import Quick
import Nimble
@testable import TestHelpers
import Dispatch

final class WhileTimeoutTests: AsyncSpec {
    override class func spec() {
       
        actor ConditionActor {
            var condition = false
            
            func updateCondition(_ value: Bool) {
                condition = value
            }
            
            func getCondition() -> Bool {
                return condition
            }
        }
        
        describe("whileTimeout") {

            it("should timeout if condition never becomes true") {
                let status = Status()
                
                let startTime = Date()

                let result = await whileTimeout(seconds: 3) { false }
                
                let duration = Date().timeIntervalSince(startTime)

                print("⏳ Actual timeout duration: \(duration) seconds") // ✅ DEBUG output

                expect(result).to(beFalse(), description: "Expected whileTimeout to return false after timing out")
                expect(duration).to(beCloseTo(3.0, within: 0.2), description: "whileTimeout should respect timeout duration")
            }
            
            it("should not wait if the condition is already true") {
                let startTime = ContinuousClock().now
                
                let result = await whileTimeout(seconds: 2) { true }
                
                let duration = ContinuousClock().now - startTime
                let seconds = Double(duration.components.attoseconds) / 1_000_000_000_000_000_000
                
                expect(result).to(beTrue(), description: "Expected whileTimeout to return true immediately")
                expect(seconds).to(beCloseTo(0, within: 0.1), description: "whileTimeout should exit immediately when condition is met")
            }

            it("should return true if condition becomes true before timeout") {
                let conditionActor = ConditionActor()
                
                Task {
                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s delay
                    await conditionActor.updateCondition(true)
                }
                
                let result = await whileTimeout(seconds: 2) {
                    await conditionActor.getCondition()
                }
                
                expect(result).to(beTrue(), description: "Expected whileTimeout to return true when condition becomes true before timeout")
            }
            
            it("should allow yielding and still work") {
                let conditionActor = ConditionActor()
                
                Task {
                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s delay
                    await Task.yield()
                    await conditionActor.updateCondition(true)
                }
                
                let result = await whileTimeout(seconds: 2) {
                    await Task.yield()
                    return await conditionActor.getCondition()
                }
                
                expect(result).to(beTrue(), description: "Expected whileTimeout to work with Task.yield() inside")
            }

            it("should handle zero timeout correctly") {
                let result = await whileTimeout(seconds: 0) { false }
                expect(result).to(beFalse(), description: "Expected whileTimeout(0) to return false immediately")
            }

            it("should handle a long timeout correctly") {
                let conditionActor = ConditionActor()
                
                Task {
                    try? await Task.sleep(nanoseconds: 2_000_000_000) // 2s delay
                    await conditionActor.updateCondition(true)
                }
                
                let startTime = Date()
                let result = await whileTimeout(seconds: 5) { await conditionActor.getCondition() }
                let duration = Date().timeIntervalSince(startTime)
                
                expect(result).to(beTrue(), description: "Expected whileTimeout to wait up to 2s and return true")
                expect(duration).to(beCloseTo(5, within: 0.2), description: "whileTimeout should return as soon as condition is met")
            }
        }
    }
}
