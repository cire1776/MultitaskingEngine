//
//  SynchronizeTests.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 3/28/25.
//  Created by ULang Integration Suite
//

import Quick
import Nimble
@testable import MultitaskingEngine

final class SynchronizeTests: AsyncSpec {
    override class func spec() {
        describe("Synchronize") {
            var sourceContext: StreamExecutionContext!
            var destinationContext: StreamExecutionContext!

            beforeEach {
                sourceContext = StreamExecutionContext()
                destinationContext = StreamExecutionContext()
            }

            it("appends a single value from source to destination") {
                sourceContext["fileOutput"] = .success(["line1"])
                destinationContext["contents"] = .success(["existing"])

                let sync = Synchronize(
                    aliasMap: ["input": "fileOutput",
                              "output": "contents"],
                    source: sourceContext,
                    destination: destinationContext,
                )

                expect(sync.process()).to(equal(.proceed))

                let result = try? destinationContext["contents"].get() as? [String]
                expect(result).to(equal(["existing", "line1"]))
            }

            it("creates the destination stream if it does not exist") {
                sourceContext["output"] = .success(["new"])

                let sync = Synchronize(
                    aliasMap: ["input": "output",
                    "output": "merged"],
                    source: sourceContext,
                    destination: destinationContext
                )

                expect(sync.process()).to(equal(.proceed))

                let result = try? destinationContext["merged"].get() as? [String]
                expect(result).to(equal(["new"]))
            }

            it("handles multiple items from source correctly") {
                sourceContext["output"] = .success(["a", "b"])
                destinationContext["contents"] = .success(["start"])

                let sync = Synchronize(
                    aliasMap: ["input": "output",
                               "output": "contents"],
                    source: sourceContext,
                    destination: destinationContext
                )

                expect(sync.process()).to(equal(.proceed))

                let result = try? destinationContext["contents"].get() as? [String]
                expect(result).to(equal(["start", "a", "b"]))
            }

            it("returns .notAvailable if the source stream is missing") {
                let sync = Synchronize(
                    aliasMap: ["input": "missingInput",
                               "output": "contents"],
                    source: sourceContext,
                    destination: destinationContext
                )

                expect(sync.process()).to(equal(.notAvailable))
            }

            it("returns .notAvailable if source is not a [String]") {
                sourceContext["bad"] = .success(42)

                let sync = Synchronize(
                    aliasMap: [
                        "input": "bad",
                        "output": "contents"
                    ],
                    source: sourceContext,
                    destination: destinationContext
                )

                expect(sync.process()).to(equal(.notAvailable))
            }

            it("returns .notAvailable if destination is not a [String]") {
                sourceContext["data"] = .success(["a"])
                destinationContext["contents"] = .success("wrong type")

                let sync = Synchronize(
                    aliasMap: ["input": "data",
                               "output": "contents"],
                    source: sourceContext,
                    destination: destinationContext
                )

                expect(sync.process()).to(equal(.notAvailable))
            }
        }
    }
}
