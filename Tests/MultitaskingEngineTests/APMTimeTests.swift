//
//  APMTimeTests.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 3/12/25.
//

import Foundation
import Quick
import Nimble
@testable import MultitaskingEngine

final class APMTimeTests: AsyncSpec {
    override class func spec() {
        describe("APMTime") {
            
            context("Initialization & Monotonic Behavior") {
                it("should return an increasing timestamp over time") {
                    let t1 = APMTime()
                    try await Task.sleep(nanoseconds: 10_000_000) // 10ms delay
                    let t2 = APMTime()
                    expect(t2.preciseRelativeTimestamp).to(beGreaterThan(t1.preciseRelativeTimestamp)) // ✅ Ensure time moves forward
                }

                it("should maintain relative consistency with system clock") {
                    let start = DispatchTime.now().uptimeNanoseconds
                    let t1 = APMTime()
                    try await Task.sleep(nanoseconds: 50_000_000) // 50ms delay
                    let t2 = APMTime()
                    
                    let elapsed = Double(t2.preciseRelativeTimestamp - t1.preciseRelativeTimestamp)
                    let actualElapsed = Double( DispatchTime.now().uptimeNanoseconds - start)
                    
                    expect(elapsed).to(beCloseTo(actualElapsed, within: 50_000))
                }
            }
            
            context("Timestamp Formatting") {
                it("should correctly format timestamps with microseconds precision") {
                    let timestamp = APMTime()
                    let formatted = timestamp.formattedTimestamp()
                    
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSS"
                    formatter.timeZone = TimeZone(abbreviation: "UTC")
                    
                    let expected = formatter.string(from: timestamp.absoluteTimestamp)
                    
                    expect(formatted).to(equal(expected))
                }
                
                it("should correctly format timestamps in ISO 8601 with nanoseconds") {
                    let timestamp = APMTime()
                    let formatted = timestamp.formattedISO8601Timestamp()
                    
                    let formatter = ISO8601DateFormatter()
                    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                    
                    let expectedISO = formatter.string(from: timestamp.absoluteTimestamp)
                    let expectedSeconds = Int(timestamp.absoluteTimestamp.timeIntervalSince1970)
                    let expectedNanoseconds = Int((timestamp.absoluteTimestamp.timeIntervalSince1970 - Double(expectedSeconds)) * 1_000_000_000)
                    
                    let expectedFinalISO = expectedISO.replacingOccurrences(of: "\\.\\d{6}", with: String(format: ".%09d", expectedNanoseconds), options: .regularExpression)
                    
                    expect(formatted).to(equal(expectedFinalISO))
                }

                it("should correctly format nanosecond timestamps in human-readable form") {
                    let timestamp = APMTime()
                    let formatted = timestamp.formattedNanoseconds()

                    let numberFormatter = NumberFormatter()
                    numberFormatter.numberStyle = .decimal
                    numberFormatter.groupingSeparator = "_"
                    let expected = numberFormatter.string(from: NSNumber(value: timestamp.preciseRelativeTimestamp))

                    expect(formatted).to(equal(expected))
                }
            }
            
            context("Comparability") {
                it("should correctly compare APMTime instances") {
                    let t1 = APMTime()
                    try await Task.sleep(nanoseconds: 10_000_000) // 10ms delay
                    let t2 = APMTime()
                    
                    expect(t1).to(beLessThan(t2))
                }
                
                it("should not consider equal timestamps as less than each other") {
                    let t1 = APMTime()
                    let t2 = t1
                    
                    expect(t1).toNot(beLessThan(t2))
                }
            }
        }
    }
}
