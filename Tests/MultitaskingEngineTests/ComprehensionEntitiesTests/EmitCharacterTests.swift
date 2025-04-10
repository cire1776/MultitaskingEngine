//
//  EmitCharacterTests.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 4/7/25.
//

import Quick
import Nimble
@testable import MultitaskingEngine
@testable import TestHelpers

final class EmitCharacterSpec: AsyncSpec {
    override class func spec() {
        describe("EmitCharacter") {
            func createEmitter(with input: String, output: String = "output") -> (context: SubscriptionStreamExecutionContext, emitter: EmitCharacter) {
                let context = SubscriptionStreamExecutionContext()
                context["input"] = .success(input)
                context.ensure(output, defaultValue: "~nil~")

                let emitter = EmitCharacter(executionContext: context)
                emitter.initialize()

                return (context, emitter)
            }

            func emitAllCharacters(from emitter: EmitCharacter, into context: StreamExecutionContext, output: String = "output") -> [Character] {
                var result: [Character] = []

                loop: while true {
                    let entityResult = emitter.process()

                    switch entityResult {
                    case .pump:
                        if let char = (try? context[output].get()) as? Character {
                            result.append(char)
                        }
                        context.remove("input")
                    case  .proceed:
                        if let char = (try? context[output].get()) as? Character {
                            result.append(char)
                        }
//                        context.remove("input")
                        context.endTick()
                        break loop
                    case .notAvailable:
                        break loop
                    default:
                        fail("Unexpected entity result: \(entityResult)")
                        break loop
                    }
                    
                }

                return result
            }

            it("emits all characters from a simple string") {
                let (context, emitter) = createEmitter(with: "abc")
                let output = emitAllCharacters(from: emitter, into: context)
                expect(output).to(equal(["a", "b", "c"]))
            }

            it("emits nothing for empty string") {
                let (context, emitter) = createEmitter(with: "")
                let output = emitAllCharacters(from: emitter, into: context)
                expect(output).to(beEmpty())
            }

            it("handles newline characters correctly") {
                let (context, emitter) = createEmitter(with: "a\nb\nc")
                let output = emitAllCharacters(from: emitter, into: context)
                expect(output).to(equal(["a", "\n", "b", "\n", "c"]))
            }

            it("supports unicode characters") {
                let (context, emitter) = createEmitter(with: "héllö")
                let output = emitAllCharacters(from: emitter, into: context)
                expect(output).to(equal(["h", "é", "l", "l", "ö"]))
            }

            xit("returns .notAvailable after finishing the buffer") {
                let (_, emitter) = createEmitter(with: "x")
                _ = emitter.process()  // "x"
                
                let result = emitter.process()
                expect(result).to(equal(.notAvailable))
            }

            it("returns .pump when characters remain") {
                let (_, emitter) = createEmitter(with: "xy")
                let result = emitter.process()
                expect(result).to(equal(.pump(0x1)))
            }

            it("returns .proceed on final character") {
                let (_, emitter) = createEmitter(with: "z")
                let result = emitter.process()
                expect(result).to(equal(.proceed))
            }

            xit("clears state on finalize") {
                let (_, emitter) = createEmitter(with: "123")
                _ = emitter.process()
                emitter.finalize()
                let result = emitter.process()
                expect(result).to(equal(.eof))
            }
        }
    }
}
