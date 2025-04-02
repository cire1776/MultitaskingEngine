//
//  ProcessFileIntegrationTests.swift
//  MultitaskingEngine
//
//  Created by ULang Integration Suite
//

import Quick
import Nimble
@testable import MultitaskingEngine
@testable import TestHelpers

/*
 define flow processFile => {
     reading line from file
     -> print: line
     -> add_line_ending: line
     -> add line to buffer: output.
 } catch error {
     handleFileError(error, filename)
 }
 */

final class ProcessFileIntegrationTests: AsyncSpec {
    override class func spec() {

        describe("process_file integration") {
            var executionContext: StreamExecutionContext!

            beforeEach {
                executionContext = StreamExecutionContext()
            }

            it("step 1: should read a single line from a file") {
                let testPath = "/tmp/integration-file.txt"
                try? "hello".write(toFile: testPath, atomically: true, encoding: .utf8)

                executionContext["filename"] = .success(testPath)
                let readLine = ReadLineFromFile(
                    aliasMap: ["output": "line", "input": "filename"],
                    executionContext: executionContext
                )

                readLine.initialize()
                expect(readLine.next()).to(equal(.proceed))
                expect(try? executionContext["line"].get() as? String).to(equal("hello"))
                expect(readLine.next()).to(equal(.eof))
            }

            it("step 2: should print the line to stdout and leave it unchanged") {
                executionContext["line"] = .success("hello")

                let printLine = Print(
                    aliasMap: ["input": "line"],
                    executionContext: executionContext
                )

                let output = captureStdOut {
                    _ = printLine.process()
                }

                expect(output).to(equal("hello"))  // ✅ Make sure it actually printed
                expect(try? executionContext["line"].get() as? String).to(equal("hello"))  // ✅ No mutation
            }

            it("step 3: should add a line ending to the line") {
                executionContext["line"] = .success("hello")

                let addLineEnding = AddLineEnding(
                    aliasMap: ["input": "line"],
                    executionContext: executionContext
                )

                addLineEnding.initialize()
                expect(addLineEnding.process()).to(equal(.proceed))
                expect(try? executionContext["line"].get() as? String).to(equal("hello\n"))
            }

            it("step 4: should append the terminated line to a buffer") {
                executionContext["terminated"] = .success("hello\n")

                let addLineToBuffer = AddLineToBuffer(
                    aliasMap: ["input": "terminated"],
                    executionContext: executionContext
                )

                addLineToBuffer.initialize()
                
                expect(addLineToBuffer.process()).to(equal(.proceed))

                let buffer = try? executionContext[addLineToBuffer.outputStream].get() as? [String]
                expect(buffer).toNot(beNil())
                expect(buffer!).to(contain("hello\n"))
            }
        }
        
        describe("process_file multi-tick integration") {
            var executionContext: StreamExecutionContext!

            beforeEach {
                executionContext = StreamExecutionContext()
            }

            it("should process multiple lines from a file and accumulate them in a buffer") {
                // ✅ Setup test file with multiple lines
                let testPath = "/tmp/integration-multiline.txt"
                let fileContent = "line 1\nline 2\nline 3"
                try? fileContent.write(toFile: testPath, atomically: true, encoding: .utf8)

                // ✅ Initial setup of data source and transformation entities
                executionContext["filename"] = .success(testPath)

                let readLine = ReadLineFromFile(
                    aliasMap: ["input": "filename", "output": "line"],
                    executionContext: executionContext
                )

                let printLine = Print(
                    aliasMap: ["input": "line"],
                    executionContext: executionContext
                )

                let addLineEnding = AddLineEnding(
                    aliasMap: ["input": "line"],
                    executionContext: executionContext
                )

                let addLineToBuffer = AddLineToBuffer(
                    aliasMap: ["input": "line", "output": "output"],
                    executionContext: executionContext
                )

                // ✅ Initialize all entities that need it
                readLine.initialize()
                addLineEnding.initialize()
                addLineToBuffer.initialize()

                var printedLines: [String] = []

                // ✅ Main tick loop (simulating comprehension)
                tickLoop: while true {
                    switch readLine.next() {
                    case .proceed:
                        // Print line
                        let printed = captureStdOut {
                            _ = printLine.process()
                        }
                        printedLines.append(printed)

                        // Add line ending
                        _ = addLineEnding.process()

                        // Append to buffer
                        _ = addLineToBuffer.process()

                        // Clear non-persistent streams (simulate EC tick boundary)
                        executionContext.endTick()

                    case .eof:
                        break tickLoop

                    default:
                        fail("Unexpected result from readLine")
                        break tickLoop
                    }
                }

                // ✅ Final expectations

                let result = try? executionContext["output"].get() as? [String]
                expect(result).toNot(beNil())
                expect(result!).to(equal([
                    "line 1\n",
                    "line 2\n",
                    "line 3\n"
                ]))

                expect(printedLines).to(equal([
                    "line 1",
                    "line 2",
                    "line 3"
                ]))
            }
            
            it("retains empty lines in the buffer") {
                let path = "/tmp/empty-line-test.txt"
                try? "line 1\n\nline 3".write(toFile: path, atomically: true, encoding: .utf8)

                executionContext["filename"] = .success(path)

                let readLine = ReadLineFromFile(
                    aliasMap: ["input": "filename", "output": "line"],
                    executionContext: executionContext
                )

                let addLineEnding = AddLineEnding(
                    aliasMap: ["input": "line"],
                    executionContext: executionContext
                )

                let addLineToBuffer = AddLineToBuffer(
                    aliasMap: ["input": "line", "output": "output"],
                    executionContext: executionContext
                )

                readLine.initialize()
                addLineEnding.initialize()
                addLineToBuffer.initialize()

                while readLine.next() == .proceed {
                    _ = addLineEnding.process()
                    _ = addLineToBuffer.process()
                    executionContext.endTick()
                }

                let result = try? executionContext["output"].get() as? [String]
                expect(result).to(equal(["line 1\n", "\n", "line 3\n"])) // ✅ Must retain empty line
            }
        }
    }
}
