//
//  ComprehensionHelpers.swift
//  MultitaskingEngine
//
//  Created by Eric Russell on 4/10/25.
//
@testable import MultitaskingEngine

func runEntity<T, E>(
    input: [Any],
    outputStream: String,
    using entityFactory: (StreamExecutionContext) -> E,
    execute: (E) -> EntityResult,
    drain: ((E) -> EntityResult)? = nil,
    extract: ((Any) -> [T]?)? = nil
) async -> [T] {
    let context = SubscriptionStreamExecutionContext()
    let entity = entityFactory(context)

    var output: [T] = []

    for element in input {
        context["input"] = .success(element)
        let result = execute(entity)

        switch result {
        case .proceed, .pump:
            if let raw = try? context[outputStream].get() {
                if let transform = extract {
                    output += transform(raw) ?? []
                } else if let single = raw as? T {
                    output.append(single)
                }
            }
        case .eof, .notAvailable:
            break
        default:
            continue
        }
    }

    if let drain = drain {
        _ = drain(entity)
        if let raw = try? context[outputStream].get() {
            if let transform = extract {
                output += transform(raw) ?? []
            } else if let single = raw as? T {
                output.append(single)
            }
        }
    }

    return output
}

func runCollectEntity<T, E>(
    input: [Any],
    outputStream: String,
    using entityFactory: (StreamExecutionContext) -> E,
    execute: (E) -> EntityResult,
    drain: ((E) -> EntityResult)? = nil
) async -> [T] {
    let context = SubscriptionStreamExecutionContext()
    let entity = entityFactory(context)

    var output: [T] = []

    for element in input {
        context["input"] = .success(element)
        let result = execute(entity)

        switch result {
        case .proceed, .pump:
            if let raw = try? context[outputStream].get() {
                if let single = raw as? T {
                    output.append(single)
                }
            }
        case .eof, .notAvailable:
            break
        default:
            continue
        }
    }

    if let drain = drain {
        _ = drain(entity)
    }
    output = (try? context[outputStream].get() as? [T]) ?? []
    return output
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

func preinits(_ streams: [String: Any?]) -> (StreamExecutionContext) -> Lint {
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
    with contextActions: (StreamExecutionContext) throws -> (preinit: Lint, extract: () -> T?)
) async -> T? where Comp: Comprehension.Subscription {
    let context = SubscriptionStreamExecutionContext()

    let result = try? contextActions(context)
    let comp = blueprint(context)

    let instance = comp.instantiate(preinitialization_lint: result?.preinit, executionContext: context)
    let runner = ManualLintRunner(provider: instance)
    _ = await runner.executeAll()

    return result?.extract()
}
