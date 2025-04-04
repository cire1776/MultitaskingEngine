import Foundation
import Quick
import Nimble
@testable import MultitaskingEngine
import PointerUtilities
import Atomics

class ExecutionContextSpec: AsyncSpec {
    override class func spec() {
        describe("StreamExecutionContext") {

            var ctx: StreamExecutionContext!

            beforeEach {
                ctx = StreamExecutionContext()
            }

            it("stores and retrieves named variables") {
                ctx["alpha"] = .success(42)
                expect(try? ctx["alpha"].get() as? Int).to(equal(42))
            }

            it("stores and retrieves nil values") {
                ctx["nullable"] = .success(nil)
                expect(try? ctx["nullable"].get()).to(beNil())
            }

            it("differentiates between missing keys and stored nil") {
                ctx["a"] = .success(nil)
                expect(ctx.containsKey("a")).to(beTrue())
                expect(ctx.containsKey("b")).to(beFalse())
            }

            it("resets and clears stored variables") {
                ctx["resettable"] = .success("temp")
                ctx["resettable"] = .failure(.invalidVariableType)
                expect(try? ctx["resettable"].get()).to(beNil())
            }

            xit("stores and retrieves indexed variables") {
                ctx["0"] = .success("first")
                ctx["1"] = .success("second")
                expect(try? ctx["0"].get() as? String).to(equal("first"))
                expect(try? ctx["1"].get() as? String).to(equal("second"))
            }

            xit("returns an error for out-of-bounds index access") {
                let result = ctx["99"]
                if case .failure(let error) = result {
                    expect(error).to(equal(.invalidVariableType)) // assuming this error
                } else {
                    fail("Expected failure for invalid index")
                }
            }

            it("does not crash under concurrent reads") {
                ctx["shared"] = .success("safe")

                let threadCount = 10
                let lock = APMLock()
                let completed = ManagedAtomic<Int>(0)

                let threads = (0..<threadCount).map { _ in
                    Thread { [ctx] in
                        lock.lock()
                        defer { lock.unlock() }
                        let result = ctx!["shared"]
                        _ = try? result.get()

                        completed.wrappingIncrement(ordering: .relaxed)
                    }
                }

                for thread in threads {
                    thread.start()
                }

                let start = Date()
                while true {
                    if completed.load(ordering: .relaxed) == threadCount { break }
                    if Date().timeIntervalSince(start) > 2 { break }

                    usleep(10_000) // 10ms
                }
                expect(completed.load(ordering: .relaxed)).to(equal(threadCount))
            }
        }
    }
}
