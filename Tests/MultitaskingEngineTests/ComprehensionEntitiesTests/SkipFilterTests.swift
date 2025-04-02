//
//  SkipFilterTests.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 3/13/25.
//

import Foundation
import Quick
import Nimble
@testable import MultitaskingEngine

final class SkipFilterTests: AsyncSpec {
    override class func spec() {
        describe("SkipFilter") {
            var executionContext: StreamExecutionContext!
            var skipFilter: SkipFilter!

            beforeEach {
                executionContext = StreamExecutionContext()
                executionContext["raw_filename"] = .success("file_to_skip.txt")
                skipFilter = SkipFilter(valuesToSkip: ["file_to_skip.txt"], stream: "raw_filename", executionContext: executionContext)
            }

            it("should skip files in the exclusion list") {
                expect(skipFilter.include()).to(equal(.notAvailable))
            }

            it("should proceed when the file is not excluded") {
                executionContext["raw_filename"] = .success("allowed_file.txt")
                expect(skipFilter.include()).to(equal(.proceed))
            }
        }
    }
}
