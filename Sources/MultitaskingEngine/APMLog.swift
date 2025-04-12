//
//  APMLog.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 3/9/25.
//

import Foundation

// MARK: - Global Logging Function
public enum LogLevel: Int, Sendable, CaseIterable {
    case trace = 0  // 🔍 TRACE: Very fine-grained logs, typically for troubleshooting
    case debug      // 🛠 DEBUG: General debugging logs
    case info       // ℹ️ INFO: Normal operational messages
    case warning       // ⚠️ WARN: Something unexpected, but not critical
    case error      // ❌ ERROR: A definite problem
    case critical   // 🚨 CRITICAL: Severe issues, requiring immediate attention

    /// **Converts log level to an emoji-enhanced label**
    public static func symbol(_ level: LogLevel) -> String {
        switch level {
        case .trace:    return "🔍 TRACE"
        case .debug:    return "🛠 DEBUG"
        case .info:     return "ℹ️ INFO"
        case .warning:     return "⚠️ WARNING"
        case .error:    return "❌ ERROR"
        case .critical: return "🚨 CRITICAL"
        }
    }
}

import Swift

/// A log entry with a high resolution timestamp for strict ordering.
struct LogEntry: Comparable {
    let timestamp: APMTime
    let level: LogLevel
    let category: String
    let message: String

    static func < (lhs: LogEntry, rhs: LogEntry) -> Bool {
        return lhs.timestamp < rhs.timestamp
    }

    /// **Enum representing different log formats**
    enum LogFormat {
        case messageOnly  // "System started"
        case simple       // ✅ "[ℹ️ INFO] System started"
        case timestamped  // ✅ "[14:32:45] [ℹ️ INFO] System started"
         case detailed     // ✅ "[2025-03-12T14:32:45.123456789Z] [ℹ️ INFO] System started"
        case full         // ✅ "[6123456789012345678] [2025-03-12 14:32:45.123456789] [2025-03-12T14:32:45.123456789Z] [ℹ️ INFO] [Thread: main] System started"
    }

    func formatted(using format: LogFormat) -> String {
        let levelSymbol = LogLevel.symbol(level)
        let levelTag = "[\(levelSymbol)]"
        let categoryTag = "{\(category)}"

        switch format {
        case .messageOnly:
            return "\(levelSymbol.first!) \(message)"
        case .simple:
            return "\(levelSymbol.first!) \(categoryTag) \(message)"

        case .timestamped:
            return "[\(timestamp.formattedTimestamp())] \(levelTag) \(categoryTag): \(message)"

        case .detailed:
            return "[\(timestamp.formattedISO8601Timestamp())] [\(levelSymbol)] \(categoryTag) \(message)"

        case .full:
            return "[\(timestamp.formattedNanoseconds())] [\(timestamp.formattedTimestamp())] [\(timestamp.formattedISO8601Timestamp())] [\(levelSymbol)] \(categoryTag)  \(message)"
        }
    }
}

struct LogEntryFactory {
    static func create(level: LogLevel, category: String="None", message: String) -> LogEntry {

        return LogEntry(
            timestamp: APMTime(),
            level: level,
            category: category,
            message: message
        )
    }
}

/// A thread-safe atomic counter for sequence IDs.
final class AtomicCounter {
    private var _counter: UInt64 = 1
    private let lock = NSLock()

    init() {} // ✅ Now allows multiple instances

    func increment() -> UInt64 {
        lock.lock()
        defer { lock.unlock() }
        _counter += 1
        return _counter
    }

    func decrement() -> UInt64 {
        lock.lock()
        defer { lock.unlock() }
        _counter -= 1
        return _counter
    }

    var counter: UInt64 {
        lock.lock()
        defer { lock.unlock() }
        return _counter
    }
}

actor APMLog {
    private var queue = PriorityQueue<LogEntry>()
    //    private var _counter = AtomicCounter()
    //
    private var nextExpectedSequenceID: UInt64 = 1
    private var nextExpectedWriteID: UInt64 = 1

    private var _level: LogLevel = .debug
    private var isFlushing = false

    //    public var counter: UInt64 { _counter.counter }

    /// Function that dynamically provides the log file path
    private let logFilePathProvider: () -> URL

    public var level: LogLevel { _level }

    public func set_level(newLevel: LogLevel) { _level = newLevel }

    /// Initialize with a dynamic log file path provider
    init(logFilePathProvider: @escaping () -> URL = APMLog.defaultLogFilePath) {
        self.logFilePathProvider = logFilePathProvider
    }

    /// **Synchronous Logging Call (No `await` needed)**
    public nonisolated func log(level: LogLevel, category: String="None", message: String) {
        Task { await self._log(level: level, category: category, message: message) }
    }

    /// **Asynchronous Logging Call (Allows Awaiting Completion)**
    func asyncLog(level: LogLevel, category: String="None", message: String) async {
        await _log(level: level, category: category, message: message)
    }

    /// **Internal function that creates a `LogEntry` and enqueues it**
    private func _log(level: LogLevel, category: String="None", message: String) async {
        let entry = LogEntryFactory.create(level: level, category: category, message: message)
        await _logEntry(entry)
    }

    /// **Testable function: Enqueues a log with a given sequence ID**
#if DEBUG
    func logEntry(_ entry: LogEntry) async { await _logEntry(entry) }
#else
    private func logEntry(_ entry: LogEntry) async { await _logEntry(entry) }
#endif

    private func _logEntry(_ entry: LogEntry) async {
        await queue.push(entry)  // ✅ Enqueue log in priority queue
        await flush()       // ✅ Process the queue
    }

    /// Processes a log entry, writing immediately if in order or queuing if out of order.
    private func writeEntry(_ entry: LogEntry) async {
        writeToFile(entry)  // ✅ Log entry is safe to write
        nextExpectedWriteID += 1  // ✅ Move forward after writing
    }

    private func displayEntry(_ entry: LogEntry) {
        if entry.level.rawValue < level.rawValue { return }
        switch entry.level {
        case .debug, .trace, .info:
            print(LogLevel.symbol(entry.level), " +[\(entry.timestamp)] \(entry.level): \(entry.message)")
        default:
            fputs("\(LogLevel.symbol(entry.level)) [\(entry.timestamp)] \(entry.level): \(entry.message)" + "\n", stderr)
        }
    }

    /// Writes all queued logs that are now in the correct order.
    func flush() async {
          guard !isFlushing else {
              print("⚠️ Skipping redundant flush() call")
              return
          }

          isFlushing = true
          defer { isFlushing = false }

          print("🔄 Entering flush()")
          while let nextEntry = await queue.peekMin() {
              _ = await queue.popMin()
              displayEntry(nextEntry)
              await writeEntry(nextEntry)
          }
          print("✅ Exiting flush()")
      }

    /// Generates the default log file path.
    static func defaultLogFilePath() -> URL {
        let projectRoot = ProcessInfo.processInfo.environment["PROJECT_ROOT"] ?? FileManager.default.currentDirectoryPath
        let logsDirectory = URL(fileURLWithPath: projectRoot).appendingPathComponent("logs")

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yy-M-d-H"
        let timestamp = dateFormatter.string(from: Date())
        let logFileName = "apm_\(timestamp).log"

        // Ensure the logs directory exists
        try? FileManager.default.createDirectory(at: logsDirectory, withIntermediateDirectories: true)

        return logsDirectory.appendingPathComponent(logFileName)
    }

    //    var nextExpectedWriteID: UInt64 = 1

    /// Writes a single log entry to the log file.
    private func writeToFile(_ entry: LogEntry) {
        let logFileURL = logFilePathProvider()

        // ✅ Get pre-formatted log entry from LogEntry
        let logText = entry.formatted(using: .full) + "\n"

        do {
            if FileManager.default.fileExists(atPath: logFileURL.path) {
                let fileHandle = try FileHandle(forUpdating: logFileURL)
                defer { try? fileHandle.close() }

                fileHandle.seekToEndOfFile()
                if let data = logText.data(using: .utf8) {
                    fileHandle.write(data)
                    fileHandle.synchronizeFile()
                }
            } else {
                try logText.write(to: logFileURL, atomically: true, encoding: .utf8)
            }
        } catch {
            print("❌ Log file write error: \(error)")
        }
    }

    /// Extracts the raw timestamp (nanoseconds) from a `.full` formatted log entry.
    public static func extractTimestamp(from log: String) -> UInt64? {
        let regex = try! NSRegularExpression(pattern: #"^\[(\d+)]"#)  // ✅ Matches raw nanosecond timestamp in brackets

        guard let match = regex.firstMatch(in: log, range: NSRange(log.startIndex..., in: log)) else {
            return nil
        }

        if let range = Range(match.range(at: 1), in: log) {
            return UInt64(log[range]) // ✅ Convert extracted string to UInt64
        }

        return nil
    }
}

extension APMLog {
    /// Checks if all logs have been processed.
    var areEntriesWaiting: Bool {
        get async {
            return !( await queue.isEmpty)
        }
    }

    /// Reads log file and filters messages by `minLevel`
    func getFilteredLogs(minLevel: LogLevel, categories: [String] = []) -> [String] {
        let logFileURL = logFilePathProvider()

        guard FileManager.default.fileExists(atPath: logFileURL.path) else {
            print("❌ APMLog Error: Log file does not exist at \(logFileURL.path)")
            return []
        }

        do {
            let logData = try String(contentsOf: logFileURL, encoding: .utf8)
            print("📂 Log File Contents: \n\(logData)")
            let filtered = filterLogs(logData, minLevel: minLevel, categories: categories)
            return filtered
        } catch {
            print("❌ APMLog Error: Failed to read log file - \(error)")
            return []
        }
    }

    private func checkLogLevels(entry: String, minLevel: LogLevel) -> Bool {
        // ✅ Extract the log level from the string using regex
        let logLevelMatch = LogLevel.allCases.first { level in
            entry.contains("[\(LogLevel.symbol(level))]")
        }

        // ✅ Ensure a valid log level was found and compare against `minLevel`
        if let logLevel = logLevelMatch {
            return logLevel.rawValue >= minLevel.rawValue
        }

        return false // ❌ If no valid level was found, return false
    }

    private func filterLogs(_ logData: String, minLevel: LogLevel, categories: [String] = []) -> [String] {
        let logEntries = logData.split(separator: "\n").map { String($0) }

        return logEntries.filter { entry in
            checkCategories(in: entry, categories: categories) && checkLogLevels(in: entry, minLevel: minLevel)
        }
    }

    private func checkCategories(in entry: String, categories: [String]) -> Bool {
        guard !categories.isEmpty else { return true }

        if let match = entry.firstMatch(of: /\{(.+)\}/) {
            let category = match.1 // ✅ Extracts the first capture group (inside `{}` brackets)

            return categories.contains(String(category))
        } else {
            return false // no category in entry and categories specified
        }

     }

    private func checkLogLevels(in entry: String, minLevel: LogLevel) -> Bool {
        // ✅ Extract the log level from the string using regex
        let logLevelMatch = LogLevel.allCases.first { level in
            entry.contains("[\(LogLevel.symbol(level))]")
        }

        // ✅ Ensure a valid log level was found and compare against `minLevel`
        if let logLevel = logLevelMatch {
            return logLevel.rawValue >= minLevel.rawValue
        }

        return false // ❌ If no valid level was found, return false
    }

    /// Retrieves the project root directory, considering both CLI and Xcode.
    func getProjectRoot() -> String {
        if let xcodePath = ProcessInfo.processInfo.environment["PROJECT_ROOT"] {
            print("=== In Xcode at \(xcodePath) ===")
            return xcodePath  // Running in Xcode
        } else {
            print("=== In CLI at \(FileManager.default.currentDirectoryPath) ===")
            return FileManager.default.currentDirectoryPath  // Running in CLI
        }
    }
}

let logger = APMLog()
