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
            var executionContext: ThreadExecutionContext!
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
                executionContext = ThreadExecutionContext(uuesHandler: DefaultUUESHandler())
                readFiles = ReadFiles(basePath: testDirectory, executionContext: executionContext)

                // ✅ Setup test files
                FileManager.default.createFile(atPath: "\(testDirectory)/file1.txt", contents: nil)
                FileManager.default.createFile(atPath: "\(testDirectory)/file2.txt", contents: nil)
            }

            afterEach {
                try? FileManager.default.removeItem(atPath: testDirectory) // ✅ Cleanup
            }

            it("should enumerate all files in a directory") {
                readFiles.initialize()
                
                expect(readFiles.next()).to(equal(.proceed))
                
                var files = Set(["file1.txt", "file2.txt"])
                
                if case let .success(filename) = executionContext["raw_filename"] {
                    expect(files).to(contain(filename as! String))
                    files.remove(filename as! String)
                } else {
                    fail("No filename read #1")
                    return
                }

                expect(readFiles.next()).to(equal(.proceed))
                
                if case let .success(filename) = executionContext["raw_filename"] {
                    expect(files).to(contain(filename as! String))
                    files.remove(filename as! String)
                } else {
                    fail("No filename read #2")
                    return
                }

                expect(readFiles.next()).to(equal(.eof))
            }
        }
    }
}
