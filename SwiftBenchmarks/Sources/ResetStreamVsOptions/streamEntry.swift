
import Foundation

enum VariableStorage {
    case value(Any?, tick: Int)
    case retained(Any?)
}

func benchmark() {
    let numVariables = 100
    let numTicks = 100_000

    var variableStore: [String: VariableStorage] = [:]
    var currentTick = 0

    for i in 0..<numVariables {
        variableStore["var_\(i)"] = .value(i, tick: -1)
    }

    func runResetBasedBenchmark() -> TimeInterval {
        let start = CFAbsoluteTimeGetCurrent()

        for tick in 0..<numTicks {
            for i in 0..<numVariables {
                variableStore["var_\(i)"] = .value(i, tick: tick)
            }

            for _ in 0..<10 {
                for i in 0..<numVariables {
                    if case let .value(val, _) = variableStore["var_\(i)"] {
                        _ = val
                    }
                }
            }

            for i in 0..<numVariables {
                variableStore["var_\(i)"] = .value(nil, tick: -1)
            }
        }

        return CFAbsoluteTimeGetCurrent() - start
    }

    func runTickFilteredBenchmark() -> TimeInterval {
        let start = CFAbsoluteTimeGetCurrent()

        for tick in 0..<numTicks {
            currentTick = tick

            for i in 0..<numVariables {
                variableStore["var_\(i)"] = .value(i, tick: tick)
            }

            for _ in 0..<10 {
                for i in 0..<numVariables {
                    if case let .value(val, t) = variableStore["var_\(i)"], t == currentTick {
                        _ = val
                    }
                }
            }
        }

        return CFAbsoluteTimeGetCurrent() - start
    }

    let resetTime = runResetBasedBenchmark()
    print("🔥 Reset-Based Time: \(resetTime) seconds")

    let tickFilteredTime = runTickFilteredBenchmark()
    print("🔥 Tick-Filtered Time: \(tickFilteredTime) seconds")
}

@main
struct ExecutionBenchmarkApp {
    static func main() async {
        print("🚀 Starting Stream Reset Benchmarks...")
        benchmark()
    }
}
