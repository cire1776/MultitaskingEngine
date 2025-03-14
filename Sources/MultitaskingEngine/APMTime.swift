//
//  APMTime.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 3/12/25.
//

import Foundation

struct APMTime: Comparable  {
    static func < (lhs: APMTime, rhs: APMTime) -> Bool {
        lhs.preciseRelativeTimestamp < rhs.preciseRelativeTimestamp
    }
    
//    public static let reference = { logger.log(level: .debug, message: "Setting Reference Timestamp"); return ContinuousClock().now }()
    public static let reference = { logger.log(level: .debug, message: "Setting Reference Timestamp"); return DispatchTime.now() }()

    /// **✅ Returns the current monotonic timestamp (nanoseconds)**
    private static func monotonicNow() -> UInt64 {
        #if os(macOS) || os(iOS)
        var timebase = mach_timebase_info()
        mach_timebase_info(&timebase)

        let machNow = mach_absolute_time()
        return (machNow * UInt64(timebase.numer)) / UInt64(timebase.denom) // Convert to nanoseconds

        #elseif os(Linux)
        var ts = timespec()
        clock_gettime(CLOCK_MONOTONIC, &ts)
        return UInt64(ts.tv_sec) * 1_000_000_000 + UInt64(ts.tv_nsec)

        #elseif os(Windows)
        var frequency: LARGE_INTEGER = LARGE_INTEGER()
        var counter: LARGE_INTEGER = LARGE_INTEGER()

        QueryPerformanceFrequency(&frequency)
        QueryPerformanceCounter(&counter)

        return UInt64(counter.QuadPart) * 1_000_000_000 / UInt64(frequency.QuadPart) // Convert to nanoseconds

        #else
        fatalError("Unsupported platform: APMTime requires a monotonic clock implementation.")
        #endif
    }

    public let absoluteTimestamp: Date
    public let preciseRelativeTimestamp: UInt64

    init() {
        self.absoluteTimestamp = Date()
//        self.preciseRelativeTimestamp = UInt64(Self.reference.duration(to: ContinuousClock.now).components.attoseconds / 1_000_000_000)
//        self.preciseRelativeTimestamp = UInt64(DispatchTime.now().uptimeNanoseconds)
        self.preciseRelativeTimestamp = Self.monotonicNow()
    }

    /// **✅ Returns a human-readable timestamp with microseconds precision**
    func formattedTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSS" // ✅ Microsecond precision
        formatter.timeZone = TimeZone(abbreviation: "UTC") // ✅ Use UTC to avoid time zone inconsistencies
        return formatter.string(from: absoluteTimestamp)
    }

    /// **✅ ISO 8601 formatted timestamp with nanosecond precision**
    func formattedISO8601Timestamp() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds] // ✅ Includes sub-second precision

        let isoString = formatter.string(from: absoluteTimestamp) // "2025-03-12T14:32:45.123456Z"
        
        let seconds = Int(absoluteTimestamp.timeIntervalSince1970)
        let nanoseconds = Int((absoluteTimestamp.timeIntervalSince1970 - Double(seconds)) * 1_000_000_000)

        // ✅ Replace microseconds with nanoseconds
        return isoString.replacingOccurrences(of: "\\.\\d{6}", with: String(format: ".%09d", nanoseconds), options: .regularExpression)
    }

    /// **✅ Returns a human-readable UInt64 nanosecond count (formatted with `_`)**
    func formattedNanoseconds() -> String {
        // ✅ Format with underscores for readability
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.groupingSeparator = "_"

        return numberFormatter.string(from: NSNumber(value: preciseRelativeTimestamp)) ?? "\(preciseRelativeTimestamp)"
    }
}
