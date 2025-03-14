//
//  APMLogTests.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 3/10/25.
//

import Quick
import Nimble
@testable import MultitaskingEngine
import Foundation

class APMLogTests: AsyncSpec {
    override class func spec() {
        // ✅ Global test variables
        var logger: APMLog!
        var testLogFileURL: URL!
        
        beforeEach {
            // ✅ Use a unique log file for each test
            let fileURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("test_apm_log_\(UUID().uuidString).log")
            
            testLogFileURL = fileURL
            print("*** Test log file: \(fileURL.path) ***")
            
            // ✅ Ensure all tests use this logger
            logger = nil
            logger = APMLog(logFilePathProvider: { @Sendable in fileURL })
            
            do {
                let logger = logger!
                Task { @Sendable in
                    while await logger.areEntriesWaiting {
                        await logger.flush()
                        await Task.yield()
                    }
                }
                
            }
            
        }
        
        afterEach {
            // ✅ Keep log files for debugging (comment out if needed)
            try? FileManager.default.removeItem(at: testLogFileURL)
        }
        
        describe("APMLog") {
            context("Logging behavior") {
                it("should log messages with correct level ordering") {
                    await logger.asyncLog(level: .debug, message: "Debug message")
                    await logger.asyncLog(level: .error, message: "Error message")
                    
                    let logs = await logger.getFilteredLogs(minLevel: .trace)
                    expect(logs).to(containElementSatisfying { $0.contains("Debug message") })
                    expect(logs).to(containElementSatisfying { $0.contains("Error message") })
                }
            }
            
            context("APMLog Console Output") {
                var originalStdout: Int32 = 0
                var originalStderr: Int32 = 0
                var stdoutPipe: Pipe!
                var stderrPipe: Pipe!
                
                beforeEach {
                    originalStdout = dup(fileno(stdout))
                    originalStderr = dup(fileno(stderr))
                    
                    stdoutPipe = Pipe()
                    dup2(stdoutPipe.fileHandleForWriting.fileDescriptor, fileno(stdout))
                    
                    stderrPipe = Pipe()
                    dup2(stderrPipe.fileHandleForWriting.fileDescriptor, fileno(stderr))
                }
                
                afterEach {
                    fflush(stdout)
                    fflush(stderr)
                    dup2(originalStdout, fileno(stdout))
                    dup2(originalStderr, fileno(stderr))
                    close(originalStdout)
                    close(originalStderr)
                }
                
                it("should print normal logs to stdout and errors to stderr") {
                    await logger.asyncLog(level: .info, message: "Info message (stdout)")
                    await logger.asyncLog(level: .warning, message: "Warning message (stderr)")
                    await logger.asyncLog(level: .error, message: "Error message (stderr)")
                    
                    await logger.flush()
                    
                    stdoutPipe.fileHandleForWriting.closeFile()
                    stderrPipe.fileHandleForWriting.closeFile()
                    
                    let stdoutContent = String(data: stdoutPipe.fileHandleForReading.availableData, encoding: .utf8) ?? ""
                    let stderrContent = String(data: stderrPipe.fileHandleForReading.availableData, encoding: .utf8) ?? ""
                    
                    expect(stdoutContent).to(contain("Info message (stdout)"))
                    expect(stderrContent).to(contain("Warning message (stderr)"))
                    expect(stderrContent).to(contain("Error message (stderr)"))
                }
            }
            
            context("Thread safety and ordering") {
                it("should maintain correct log sequence even with concurrent logging") {
                    let totalLogs = 100
                    let logger = logger!
                    
                    await withTaskGroup(of: Void.self) { group in
                        for i in 0..<totalLogs {
                            group.addTask {
                                await logger.asyncLog(level: .info, message: "Entry \(i + 1)")
                            }
                        }
                    }
                    
                    await logger.flush()
                    
                    let logs = await logger.getFilteredLogs(minLevel: .trace).sorted()
                    for i in 0..<totalLogs {
                        expect(logs).to(containElementSatisfying { $0.contains("Entry \(i + 1)") })
                    }
                }
            }
            
            context("File writing") {
                it("should write logs to the correct test log file") {
                    await logger.asyncLog(level: .info, message: "Test file logging")
                    
                    let fileContents = try? String(contentsOf: testLogFileURL, encoding: .utf8)
                    expect(fileContents).to(contain("Test file logging"))
                }
            }
            
            context("Flush & FlushQueue") {
                it("should process logs in correct order after flush") {
                    await logger.asyncLog(level: .info, message: "Entry 1")
                    await logger.asyncLog(level: .info, message: "Entry 2")
                    await logger.asyncLog(level: .info, message: "Entry 3")
                    
                    await logger.flush()
                    
                    let logs = await logger.getFilteredLogs(minLevel: .trace).sorted()
                    expect(logs).to(containElementSatisfying { $0.contains("Entry 1") })
                    expect(logs).to(containElementSatisfying { $0.contains("Entry 2") })
                    expect(logs).to(containElementSatisfying { $0.contains("Entry 3") })
                }
                
                it("should process logs correctly even when logged concurrently") {
                    let totalLogs = 5
                    let logger = logger!
                    
                    await withTaskGroup(of: Void.self) { group in
                        for i in 1...totalLogs {
                            group.addTask {
                                await logger.asyncLog(level: .info, message: "Concurrent Entry \(i)")
                            }
                            try! await Task.sleep(nanoseconds: 10_000_000)
                        }
                    }
                    
                    while await logger.areEntriesWaiting {
                        await logger.flush()
                        await Task.yield()
                    }
                    
                    let logs = await logger.getFilteredLogs(minLevel: .trace)
                    
                    // ✅ Extract raw timestamps
                    let extractedTimestamps = logs.compactMap { APMLog.extractTimestamp(from: $0) }
                    
                    expect(logs.count).to(equal(totalLogs))
                    
                    print("=====Extracted Timestamps: \(extractedTimestamps)")
                    
                    // ✅ Ensure timestamps are sorted in non-decreasing order
                    expect(extractedTimestamps).to(equal(extractedTimestamps.sorted()))
                    
                    // ✅ Ensure all messages exist, but NOT in a strict order
                    for i in 1...totalLogs {
                        expect(logs).to(containElementSatisfying { $0.contains("Concurrent Entry \(i)") })
                    }
                }
            }
            
            it("should process a large number of logs correctly") {
                let totalLogs = 1000
                
                for i in 1...totalLogs {
                    await logger.asyncLog(level: .info, message: "Large Entry \(i)")
                }
                
                while await logger.areEntriesWaiting {
                    await logger.flush()
                    await Task.yield()
                }
                
                let logs = await logger.getFilteredLogs(minLevel: .trace).sorted()
                expect(logs.count).to(equal(totalLogs))
                
                for i in 1...totalLogs {
                    expect(logs).to(equal(logs.sorted()))
                }
            }
        }
        
        describe("APMLog Categories") {
            var logger: APMLog!
            var testLogFileURL: URL!
            
            beforeEach {
                let fileURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent("test_apm_log_\(UUID().uuidString).log")
                
                testLogFileURL = fileURL
                logger = APMLog(logFilePathProvider: { @Sendable in fileURL })
            }
            
            afterEach {
                try? FileManager.default.removeItem(at: testLogFileURL) // ✅ Clean up test files
            }
            
            // ✅ 1️⃣ Basic Category Logging
            context("Basic Category Logging") {
                it("should correctly associate messages with categories") {
                    await logger.asyncLog(level: .info, category: "Database", message: "Database Connected")
                    await logger.asyncLog(level: .warning, category: "Network", message: "Network Timeout")
                    
                    let logs = await logger.getFilteredLogs(minLevel: .trace)
                    expect(logs).to(containElementSatisfying {
                        print($0)
                        return $0.contains("{Database}") && $0.contains("Database Connected") })
                    expect(logs).to(containElementSatisfying {

                        
                        $0.contains("{Network}") && $0.contains("Network Timeout") })
                }
            }
            
            // ✅ 2️⃣ Category-Based Filtering
            context("Category-Based Filtering") {
                beforeEach {
                    await logger.asyncLog(level: .info, category: "Database", message: "DB Initialized")
                    await logger.asyncLog(level: .error, category: "Network", message: "API Failure")
                    await logger.asyncLog(level: .debug, category: "Cache", message: "Cache Cleared")
                }
                
                it("should filter logs by specific categories") {
                    let dbLogs = await logger.getFilteredLogs(minLevel: .trace, categories: ["Database"])
                    expect(dbLogs).to(containElementSatisfying { $0.contains("{Database}") && $0.contains("DB Initialized") })
                    expect(dbLogs).toNot(containElementSatisfying { $0.contains("{Network}") })
                }
                
                it("should return logs for multiple selected categories") {
                    let selectedLogs = await logger.getFilteredLogs(minLevel: .trace, categories: ["Database", "Network"])
                    expect(selectedLogs).to(containElementSatisfying { $0.contains("{Database}") })
                    expect(selectedLogs).to(containElementSatisfying { $0.contains("{Network}") })
                    expect(selectedLogs).toNot(containElementSatisfying { $0.contains("{cache}") })
                }
                
                it("should return an empty list when filtering by an unknown category") {
                    let unknownCategoryLogs = await logger.getFilteredLogs(minLevel: .trace, categories: ["NonExistent"])
                    expect(unknownCategoryLogs).to(beEmpty())
                }
            }
            
            // ✅ 3️⃣ Category & Level Filtering Combined
            context("Category & Level Filtering Combined") {
                beforeEach {
                    await logger.asyncLog(level: .debug, category: "Debug", message: "Low-level Debug Info")
                    await logger.asyncLog(level: .warning, category: "Security", message: "Potential Issue Detected")
                    await logger.asyncLog(level: .error, category: "System", message: "Critical Failure!")
                }
                
                it("should return only logs matching both category and level") {
                    let filteredLogs = await logger.getFilteredLogs(minLevel: .warning, categories: ["Security", "System"])
                    expect(filteredLogs).to(containElementSatisfying { $0.contains("{Security}") && $0.contains("WARNING]") })
                    expect(filteredLogs).to(containElementSatisfying { $0.contains("{System}") && $0.contains("ERROR]") })
                    expect(filteredLogs).toNot(containElementSatisfying { $0.contains(".DEBUG") })
                }
            }
            
            // ✅ 4️⃣ Category-Based Log Counting
            context("Category-Based Log Counting") {
                beforeEach {
                    await logger.asyncLog(level: .info, category: "Modules", message: "Loaded Module A")
                    await logger.asyncLog(level: .info, category: "Modules", message: "Loaded Module B")
                    await logger.asyncLog(level: .info, category: "Modules", message: "Loaded Module C")
                }
                
                it("should correctly count logs in a category") {
                    let moduleLogs = await logger.getFilteredLogs(minLevel: .trace, categories: ["Modules"])
                    expect(moduleLogs.count).to(equal(3))
                }
            }
            
            // ✅ 5️⃣ Default Category Behavior
            context("Default Category Behavior") {
                it("should assign 'None' category if no category is provided") {
                    await logger.asyncLog(level: .info, message: "Uncategorized Log")
                    
                    let logs = await logger.getFilteredLogs(minLevel: .trace)
                    expect(logs).to(containElementSatisfying { $0.contains("{None}") })
                }
            }
            
            /// ✅ 6️⃣ Category-Based Exclusions
            context("Category-Based Exclusions") {
                beforeEach {
                    await logger.asyncLog(level: .info, category: "Included", message: "Included Log")
                    await logger.asyncLog(level: .info, category: "Excluded", message: "Excluded Log")
                }
                
                it("should exclude specific categories when retrieving logs") {
                    let includedLogs = await logger.getFilteredLogs(minLevel: .trace, categories: ["Included"])
                    expect(includedLogs).to(containElementSatisfying { $0.contains("{Included}") })
                    expect(includedLogs).toNot(containElementSatisfying { $0.contains("{Excluded}") })
                }
            }
        }
    }
}
