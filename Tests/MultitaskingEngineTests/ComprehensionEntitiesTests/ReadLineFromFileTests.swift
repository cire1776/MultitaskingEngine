
//
//  ReadLineFromFileTests.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 3/15/25.
//

import Quick
import Nimble
import Foundation
@testable import MultitaskingEngine

class ReadLineFromFileTests: AsyncSpec {
    override class func spec() {
        describe("ReadLineFromFile") {
            var executionContext: StreamExecutionContext!
            var tempFilePath: String!
            var readLineFromFile: ReadLineFromFile!

            beforeEach {
                // Create a temporary test file
                let tempDirectory = FileManager.default.temporaryDirectory
                tempFilePath = tempDirectory.appendingPathComponent("test_file.txt").path

                let testContent = """
                Line 1
                Line 2
                Line 3
                """

                FileManager.default.createFile(atPath: tempFilePath, contents: testContent.data(using: .utf8), attributes: nil)

                // Set up execution context
                executionContext = StreamExecutionContext()
                executionContext["input"] = .success(tempFilePath)

                // Initialize the data source
                readLineFromFile = ReadLineFromFile(executionContext: executionContext)
            }

            afterEach {
                // Cleanup: Remove temp file
                try? FileManager.default.removeItem(atPath: tempFilePath)
            }

            it("uses default alias if no alias is provided") {
                readLineFromFile = ReadLineFromFile(executionContext: executionContext)
                readLineFromFile.initialize()

                expect(readLineFromFile.inputStream).to(equal("input"))
                expect(readLineFromFile.outputStream).to(equal("output"))
            }

            it("allows setting custom input/output aliases during initialization") {
                let aliasMap: [String: String] = ["input": "source_file", "output": "result_line"]
                readLineFromFile = ReadLineFromFile(aliasMap: aliasMap, executionContext: executionContext)
                readLineFromFile.initialize()

                expect(readLineFromFile.inputStream).to(equal("source_file"))
                expect(readLineFromFile.outputStream).to(equal("result_line"))
            }

            it("reads filename from the correct alias") {
                let aliasMap: [String: String] = ["input": "source_file"]
                executionContext["source_file"] = .success(tempFilePath)

                readLineFromFile = ReadLineFromFile(aliasMap: aliasMap, executionContext: executionContext)
                readLineFromFile.initialize()

                expect(readLineFromFile.filename).to(endWith("test_file.txt"))
            }

            it("writes to custom output alias") {
                let aliasMap: [String: String] = ["output": "processed_text"]
                executionContext["input"] = .success(tempFilePath)

                readLineFromFile = ReadLineFromFile(aliasMap: aliasMap, executionContext: executionContext)
                readLineFromFile.initialize()

                expect(readLineFromFile.next()).to(equal(.proceed))
                expect(try? executionContext["processed_text"].get() as? String).to(equal("Line 1"))
            }

            it("writes to default output stream if no alias is given") {
                executionContext["input"] = .success(tempFilePath)

                let readLine = ReadLineFromFile(aliasMap: [:], executionContext: executionContext)
                readLine.initialize()

                expect(readLine.next()).to(equal(.proceed))
                expect(try? executionContext["output"].get() as? String).to(equal("Line 1"))
            }

            it("reads lines and stores them in EC[destination]") {
                readLineFromFile.initialize()
                expect(readLineFromFile.next()).to(equal(.proceed))
                expect(try? executionContext["output"].get() as? String).to(equal("Line 1"))
                

                expect(readLineFromFile.next()).to(equal(.proceed))
                expect(try? executionContext["output"].get() as? String).to(equal("Line 2"))

                expect(readLineFromFile.next()).to(equal(.proceed))
                expect(try? executionContext["output"].get() as? String).to(equal("Line 3"))

                expect(readLineFromFile.next()).to(equal(.eof))
            }

            it("returns .eof immediately for an empty file") {
                // Create an empty file
                FileManager.default.createFile(atPath: tempFilePath, contents: Data(), attributes: nil)

                // Reinitialize the data source
                readLineFromFile = ReadLineFromFile(executionContext: executionContext)
                readLineFromFile.initialize()

                expect(readLineFromFile.next()).to(equal(.eof)) // ✅ Should return EOF immediately
            }

            it("triggers an exception if filename not given") {
                let invalidContext = StreamExecutionContext()

                let testEntity = ReadLineFromFile(executionContext: invalidContext)
                testEntity.initialize()
                
                guard case let .exception(message)? = invalidContext.pendingEvent else {
                    fail("Expected an exception event with a message, but got \(String(describing: invalidContext.pendingEvent))")
                    return
                }

                expect(message).to(contain("Filename is required in Execution Context."))
            }

            it("triggers an exception in UUES if file does not exist") {
                let invalidContext = StreamExecutionContext()
                invalidContext["input"] = .success("/invalid/path/to/nonexistent.txt")

                let testEntity = ReadLineFromFile(executionContext: invalidContext)
                testEntity.initialize()

                expect(testEntity.next()).to(equal(.unusualExecutionEvent))
                guard case let .exception(message)? = invalidContext.pendingEvent else {
                    fail("Expected an exception event with a message, but got \(String(describing: invalidContext.pendingEvent))")
                    return
                }

                expect(message).to(contain("nonexistent.txt"))
            }

            it("closes the file when finalized") {
                let fileHandle = FileHandle(forReadingAtPath: tempFilePath)
                expect(fileHandle).toNot(beNil())

                readLineFromFile.finalize()

                expect(fileHandle?.readabilityHandler).to(beNil()) // ✅ File should be closed
            }
        }
    }
}
