//
//  RerouteTests.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 3/15/25.
//

import Quick
import Nimble
@testable import MultitaskingEngine

final class RerouteEntitySpec: AsyncSpec {
    override class func spec() {
        var executionContext: StreamExecutionContext!
        var reroute: RerouteEntity!

        beforeEach {
            executionContext = StreamExecutionContext()
        }

        describe("RerouteEntity") {
            context("when initialized") {
                it("sets input and output stream names correctly") {
                    reroute = RerouteEntity(aliasMap: ["input": "source", "output": "destination"], executionContext: executionContext)
                    reroute.initialize()

                    expect(reroute.inputStream).to(equal("source"))
                    expect(reroute.outputStream).to(equal("destination"))
                }
            }

            context("when processing data") {
                beforeEach {
                    reroute = RerouteEntity(aliasMap: ["input": "source", "output": "destination"],executionContext: executionContext)
                    reroute.initialize()
                }
                
                it("successfully reroutes a value") {
                    executionContext["source"] = .success("TestData")
                    
                    let result = reroute.process()
                    
                    expect(result).to(equal(.proceed))
                    expect(try executionContext["destination"].get() as? String).to(equal("TestData"))
                }
                
                it("moves the value from source to destination and removes the original entry") {
                    executionContext["source"] = .success("test_data")
                    let result = reroute.process()
                    
                    expect(result).to(equal(.proceed))
                    expect(try? executionContext["destination"].get() as? String?).to(equal("test_data"))
                    expect(executionContext.containsKey("source")).to(beFalse())
                }
                
                it("returns .exception if the source does not exist") {
                    executionContext.remove("source")  // Simulating missing input
                    
                    reroute.initialize()
                    
                    if case let .exception(message) = executionContext.pendingEvent {              expect(message).to(equal("Missing input stream 'source' in execution context."))
                    } else {
                        fail("expected .exception event, got: \(executionContext.pendingEvent!)")
                    }
                }
            }
        }
    }
}
