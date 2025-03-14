import Foundation
import Quick
import Nimble
@testable import MultitaskingEngine
import PointerUtilities

final class ExecutionContextTests: AsyncSpec {
    override class func spec() {
        describe("ThreadExecutionContext") {
            it("registers and retrieves execution context correctly") {
                let object = NSObject()
                ThreadExecutionContext.registerContext(for: object)
                ThreadExecutionContext.setActiveContext(for: object)
                
                expect(ThreadExecutionContext.current).toNot(beNil(), description: "Execution context should be retrievable.")
            }
            
            it("switches between execution contexts correctly") {
                let object1 = NSObject()
                let object2 = NSObject()
                
                ThreadExecutionContext.registerContext(for: object1)
                ThreadExecutionContext.registerContext(for: object2)
                
                ThreadExecutionContext.setActiveContext(for: object1)
                expect(ThreadExecutionContext.current).to(beIdenticalTo(ThreadExecutionContext.contextTable[Unmanaged.passUnretained(object1).toOpaque()]))
                
                ThreadExecutionContext.setActiveContext(for: object2)
                expect(ThreadExecutionContext.current).to(beIdenticalTo(ThreadExecutionContext.contextTable[Unmanaged.passUnretained(object2).toOpaque()]))
            }
            
            it("stores and retrieves named variables") {
                let object = NSObject()
                ThreadExecutionContext.registerContext(for: object)
                ThreadExecutionContext.setActiveContext(for: object)
                
                guard let ctx = ThreadExecutionContext.current else {
                    fail("Execution context not found")
                    return
                }
                
                ctx["testVar"] = .success(42)
                expect(ctx["testVar"]).to(equalResult(42))
            }

            it("supports storing and retrieving `nil` values") {
                let object = NSObject()
                ThreadExecutionContext.registerContext(for: object)
                ThreadExecutionContext.setActiveContext(for: object)

                guard let ctx = ThreadExecutionContext.current else {
                    fail("Execution context not found")
                    return
                }

                ctx["nilVar"] = .success(nil)
                expect(ctx["nilVar"]).to(equalResult(Optional<String>.none), description: "Nil values should be storable and retrievable.")
            }
            
            it("correctly differentiates between missing keys and stored nil") {
                let object = NSObject()
                ThreadExecutionContext.registerContext(for: object)
                ThreadExecutionContext.setActiveContext(for: object)

                guard let ctx = ThreadExecutionContext.current else {
                    fail("Execution context not found")
                    return
                }

                ctx["nilVar"] = .success(nil)

                expect(ctx.containsKey("nilVar")).to(beTrue(), description: "Should detect explicitly stored nil.")
                expect(ctx.containsKey("missingVar")).to(beFalse(), description: "Should return false for missing keys.")

                if case let .failure(error) = ctx["missingVar"] {
                    expect(error).to(equal(ExecutionContextError.variableNotFound("missingVar")))
                } else {
                    fail("Expected variableNotFound error, but got \(ctx["missingVar"])")
                }
            }
            
            it("stores and retrieves indexed variables") {
                let object = NSObject()
                ThreadExecutionContext.registerContext(for: object)
                ThreadExecutionContext.setActiveContext(for: object)

                guard let ctx = ThreadExecutionContext.current else {
                    fail("Execution context not found")
                    return
                }

                ctx[3] = .success(100)
                expect(ctx[3]).to(equalResult(100))
            }

            it("returns an error for out-of-bounds index access") {
                let object = NSObject()
                ThreadExecutionContext.registerContext(for: object)
                ThreadExecutionContext.setActiveContext(for: object)

                guard let ctx = ThreadExecutionContext.current else {
                    fail("Execution context not found")
                    return
                }

                let result = ctx[2000] // Accessing an out-of-bounds index

                if case let .failure(error) = result {
                    expect(error).to(equal(ExecutionContextError.indexOutOfRange(2000)))
                } else {
                    fail("Expected indexOutOfRange(2000), but got \(result)")
                }
            }
            
            it("ensures context isolation between instances") {
                let object1 = NSObject()
                let object2 = NSObject()
                
                ThreadExecutionContext.registerContext(for: object1)
                ThreadExecutionContext.registerContext(for: object2)
                
                ThreadExecutionContext.setActiveContext(for: object1)
                ThreadExecutionContext.current?["testVar"] = .success(42)
                
                ThreadExecutionContext.setActiveContext(for: object2)
                ThreadExecutionContext.current?["testVar"] = .success(100)
                
                ThreadExecutionContext.setActiveContext(for: object1)
                expect(ThreadExecutionContext.current?["testVar"]).to(equalResult(42))
                
                ThreadExecutionContext.setActiveContext(for: object2)
                expect(ThreadExecutionContext.current?["testVar"]).to(equalResult(100))
            }

            it("resets the context and clears stored variables") {
                let object = NSObject()
                ThreadExecutionContext.registerContext(for: object)
                ThreadExecutionContext.setActiveContext(for: object)

                guard let ctx = ThreadExecutionContext.current else {
                    fail("Execution context not found")
                    return
                }

                ctx["testVar"] = .success(42)
                ctx.reset()

                if case let .failure(error) = ctx["testVar"] {
                    expect(error).to(equal(.variableNotFound("testVar")), description: "Variable should be cleared after reset.")
                } else {
                    fail("Expected variable to be cleared.)")
                }
            }

            it("ensures no data races with concurrent reads") {
                let object = NSObject()
                ThreadExecutionContext.registerContext(for: object)
                ThreadExecutionContext.setActiveContext(for: object)

                let numberOfThreads = 10
                let asyncSemaphore = AsyncSemaphore(expectedCount: numberOfThreads)

                for _ in 0..<numberOfThreads {
                    Task {
                        if let ctx = ThreadExecutionContext.current {
                            ctx["testVar"] = .success(42)
                            if let value = try? ctx["testVar"].get() as? Int {
                                expect(value).to(equal(42))
                            } else {
                                fail("Failed to retrieve testVar")
                            }
                        } else {
                            fail("Failed to retrieve current context")
                        }

                        await asyncSemaphore.signal()
                    }
                }

                await asyncSemaphore.wait()
            }
        }
    }
}

/// ✅ **Helper for comparing `Result` values in tests**
func equalResult<T: Equatable>(_ expectedValue: T) -> Nimble.Matcher<Result<Any?, ExecutionContextError>> {
    return Matcher.define("equal Result success value \(expectedValue)") { actualExpression, msg in
        guard let actual = try actualExpression.evaluate() else {
            return MatcherResult(status: .fail, message: msg.appended(message: "but got nil"))
        }

        switch actual {
        case .success(let value):
            if let value = value as? T, value == expectedValue {
                return MatcherResult(status: .matches, message: msg)
            } else {
                return MatcherResult(status: .fail, message: msg.appended(message: "but got \(String(describing: value))"))
            }
        case .failure(let error):
            return MatcherResult(status: .fail, message: msg.appended(message: "but got failure: \(error)"))
        }
    }
}
