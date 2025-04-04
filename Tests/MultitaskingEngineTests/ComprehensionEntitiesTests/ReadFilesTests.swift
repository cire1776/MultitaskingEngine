//
//  ReadFilesTests.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 3/13/25.
//

import Foundation
import Quick
import Nimble

@testable import MultitaskingEngine

final class ReadFilesTests: AsyncSpec {
    override class func spec() {
        describe("ReadFiles") {
            var executionContext: StreamExecutionContext!
            var readFiles: ReadFiles!
            let testDirectory = "/tmp/test-files"
            let fileManager = FileManager.default

            do {
                try fileManager.createDirectory(atPath: testDirectory, withIntermediateDirectories: true, attributes: nil)
                print("✅ Directory created at \(testDirectory)")
            } catch {
                print("❌ Failed to create directory: \(error)")
            }

            beforeEach {
                executionContext = StreamExecutionContext()
                readFiles = ReadFiles(
                    aliasMap: ["filename": "filename", "pathname": "pathname"],
                    executionContext: executionContext
                )

                // ✅ Setup test files
                FileManager.default.createFile(atPath: "\(testDirectory)/file1.txt", contents: nil)
                FileManager.default.createFile(atPath: "\(testDirectory)/file2.txt", contents: nil)

                executionContext["baseDir"] = .success(testDirectory)
                readFiles.initialize()
            }

            afterEach {
                try? FileManager.default.removeItem(atPath: testDirectory)
            }

            it("should enumerate all files and emit filename + pathname") {
                expect(readFiles.next()).to(equal(.proceed))

                var files = Set(["file1.txt", "file2.txt"])

                if case let .success(filename) = executionContext["filename"],
                   case let .success(pathname) = executionContext["pathname"] {
                    expect(files).to(contain(filename as! String))
                    expect(pathname as? String).to(contain(filename as! String))
                    expect(pathname as? String).to(beginWith(testDirectory))
                    files.remove(filename as! String)
                } else {
                    fail("Missing filename or pathname on first tick")
                }

                expect(readFiles.next()).to(equal(.proceed))

                if case let .success(filename) = executionContext["filename"],
                   case let .success(pathname) = executionContext["pathname"] {
                    expect(files).to(contain(filename as! String))
                    expect(pathname as? String).to(contain(filename as! String))
                    expect(pathname as? String).to(beginWith(testDirectory))
                    files.remove(filename as! String)
                } else {
                    fail("Missing filename or pathname on second tick")
                }

                expect(readFiles.next()).to(equal(.eof))
                expect(files).to(beEmpty())
            }
        }

        describe("with customizable stream aliases") {
            var executionContext: StreamExecutionContext!
            var readFiles: ReadFiles!
            let dummyPath = "/tmp/alias-test"
            let fileManager = FileManager.default

            beforeEach {
                try? fileManager.createDirectory(atPath: dummyPath, withIntermediateDirectories: true)
                fileManager.createFile(atPath: "\(dummyPath)/alias.txt", contents: nil)
                executionContext = StreamExecutionContext()
            }

            afterEach {
                try? fileManager.removeItem(atPath: dummyPath)
            }

            it("uses custom filename alias") {
                readFiles = ReadFiles(
                    aliasMap: ["filename": "custom_filename"],
                    executionContext: executionContext
                )

                readFiles.initialize()
                expect(readFiles.next()).to(equal(.proceed))

                expect(executionContext["custom_filename"]).toNot(beNil())
                expect(executionContext["pathname"]).toNot(beNil()) // default pathname
            }

            it("uses custom pathname alias") {
                readFiles = ReadFiles(
                    aliasMap: ["pathname": "custom_path"],
                    executionContext: executionContext
                )

                readFiles.initialize()
                expect(readFiles.next()).to(equal(.proceed))

                expect(executionContext["filename"]).toNot(beNil()) // default filename
                expect(executionContext["custom_path"]).toNot(beNil())
            }

            it("uses both custom aliases if provided") {
                readFiles = ReadFiles(
                    aliasMap: ["filename": "fn", "pathname": "pn"],
                    executionContext: executionContext
                )

                readFiles.initialize()
                expect(readFiles.next()).to(equal(.proceed))

                expect(executionContext["fn"]).toNot(beNil())
                expect(executionContext["pn"]).toNot(beNil())
            }

            it("defaults to 'filename' and 'pathname' if no aliases are provided") {
                readFiles = ReadFiles(
                    aliasMap: [:],
                    executionContext: executionContext
                )

                readFiles.initialize()
                expect(readFiles.next()).to(equal(.proceed))

                expect(executionContext["filename"]).toNot(beNil())
                expect(executionContext["pathname"]).toNot(beNil())
            }
            
            it("enumerates only files within the specified basePath") {
                let isolatedPath = "/tmp/isolated-dir"
                try? FileManager.default.createDirectory(atPath: isolatedPath, withIntermediateDirectories: true)
                defer { try? FileManager.default.removeItem(atPath: isolatedPath) }

                FileManager.default.createFile(atPath: "\(isolatedPath)/alpha.txt", contents: nil)
                FileManager.default.createFile(atPath: "\(isolatedPath)/beta.txt", contents: nil)

                executionContext["baseDir"] = .success(isolatedPath)
                
                readFiles = ReadFiles(
                    aliasMap: ["filename": "filename"],
                    executionContext: executionContext
                )

                readFiles.initialize()

                expect(readFiles.next()).to(equal(.proceed))
                expect(readFiles.next()).to(equal(.proceed))
                expect(readFiles.next()).to(equal(.eof)) // ✅ Only those two files
            }
        }
    }
}
