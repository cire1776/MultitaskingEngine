//
//  ModelComprehensionTests.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 3/30/25.
//

import Foundation
import Quick
import Nimble
@testable import MultitaskingEngine

final class ComprehensionModelTests: AsyncSpec {
    override class func spec() {
        describe("Comprehension_1A5D27B3 execution") {
            var executionContext: StreamExecutionContext!

            beforeEach {
                executionContext = StreamExecutionContext()
            }

            it("reads and concatenates multiple files into contents") {
                // ✅ Setup test directory and files
                let dir = "/tmp/comprehension-model-test"
                try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
                try? "alpha".write(toFile: "\(dir)/a.txt", atomically: true, encoding: .utf8)
                try? "bravo".write(toFile: "\(dir)/b.txt", atomically: true, encoding: .utf8)
                try? "skip me".write(toFile: "\(dir)/output.txt", atomically: true, encoding: .utf8)

                // ✅ Setup execution context
                executionContext["message"] = .success("Concatenation complete! Output saved in: output.txt")
                executionContext.ensure("contents", defaultValue: [String]())

                // ✅ Run comprehension
                let comprehension = Comprehension_1A5D27B3(executionContext: executionContext)
                let instance = comprehension.instantiate(preinitialization_lint: {_ in executionContext["baseDir"] = .success(dir) ; return .firstRun })
                let runner = ManualLintRunner(provider: instance)
                let result = runner.execute()

                // ✅ Validate output stream
                let contents = try? executionContext["contents"].get() as? [String]
                expect(contents).toNot(beNil())
                expect(contents).to(contain("alpha\n"))
                expect(contents).to(contain("bravo\n"))
                expect(contents).toNot(contain("skip me"))

                // ✅ Final result
                let context = executionContext
                expect(result).to(equal(.completed))
            }
        }
    }
}
