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
            var executionContext: ThreadExecutionContext!
            var skipFilter: SkipFilter!

            beforeEach {
                executionContext = ThreadExecutionContext(uuesHandler: DefaultUUESHandler())
                executionContext.setStream(setter: ("raw_filename", "file_to_skip.txt"))
                skipFilter = SkipFilter(valuesToSkip: ["file_to_skip.txt"], stream: "raw_filename", executionContext: executionContext)
            }

            it("should skip files in the exclusion list") {
                expect(skipFilter.include()).to(equal(.notAvailable))
            }

            it("should proceed when the file is not excluded") {
                executionContext.setStream(setter: ("raw_filename", "allowed_file.txt"))
                expect(skipFilter.include()).to(equal(.proceed))
            }
        }
    }
}
