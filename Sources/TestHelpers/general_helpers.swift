//
//  general_helpers.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 2/28/25.
//
import Foundation
@testable import MultitaskingEngine

func waitForCondition(_ condition: @escaping () -> Bool, timeout: TimeInterval = 0.5, interval: TimeInterval = 0.01) async {
    let maxRetries = Int(timeout / interval)

    for _ in 0..<maxRetries {
        if condition() { return }  // ✅ Exit early if condition is met
        try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
    }

    print("⚠️ Timeout reached waiting for condition.")
}

func createPreinitLint(value: Any?, executionContext: StreamExecutionContext) -> Lint {
    return { [executionContext] _ in
        executionContext.ensure("input", defaultValue: value)
        executionContext.ensure("comma_delimited_line", defaultValue: "~nil~")
        return .running }
}

func simplePreinit(_ stream: String = "input", default: Any = "~nil~") -> (StreamExecutionContext) -> Lint {
    return { ctx in
        return { _ in
            ctx.ensure(stream, defaultValue: `default`)
            return .running
        }
    }
}

func preinits(_ streams:[String: Any?]) -> (StreamExecutionContext) -> Lint {
    return { context in
        return { _ in
            streams.forEach { stream, `default` in
                context.ensure(stream, defaultValue: `default`)
            }
            return .running
        }
    }
}

func runComprehension<Comp, T>(
    input: Any,
    blueprint: (StreamExecutionContext) -> Comp,
    with contextActions: (StreamExecutionContext) throws -> (preinit: Lint, extract: ()->T?)
) async -> T? where Comp: Comprehension.Subscription {
    let context = SubscriptionStreamExecutionContext()
    
    let result = try? contextActions(context)
    let comp = blueprint(context)
    
    let instance = comp.instantiate(preinitialization_lint: result?.preinit, executionContext: context)
    let runner = ManualLintRunner(provider: instance)
    _ = await runner.executeAll()
    
    return result?.extract()
}
