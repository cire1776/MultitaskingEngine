//
//  APMLockTests.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 3/7/25.
//

import Quick
import Nimble
@testable import MultitaskingEngine

class APMLockSpec: AsyncSpec {
    override class func spec() {
        describe("APMLock") {
            var lock: APMLock!

            beforeEach {
                lock = APMLock()
            }

            context("when locking and unlocking") {
                it("should allow locking and unlocking") {
                    expect(lock.tryLock()).to(beTrue())
                    lock.unlock()
                }
            }

            context("when trying to lock an already locked lock") {
                it("should fail to acquire the lock") {
                    lock.lock()
                    expect(lock.tryLock()).to(beFalse())
                    lock.unlock()
                }
            }

            context("when using withLock") {
                it("should execute the closure while holding the lock") {
                    var value = 0

                    let result = lock.withLock {
                        value = 42
                        return value
                    }

                    expect(result).to(equal(42))
                    expect(value).to(equal(42))
                }
            }
        }
    }
}
