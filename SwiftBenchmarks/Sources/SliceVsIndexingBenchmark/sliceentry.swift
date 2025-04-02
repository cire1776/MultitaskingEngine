import Foundation
import Atomics
import Dispatch
import Shared

let iterations = 1_000_000  // ✅ Global iteration count

@inline(never)
func indexBasedExecution(lints: [() -> Void], iterations: Int) {
    var index = 0
    while index < lints.count {
        lints[index]()
        index += 1
    }
}

@inline(never)
func dropFirstExecution(lints: [() -> Void], iterations: Int) {
    var dropped = lints[...]
    while !dropped.isEmpty {
        dropped.first?()
        dropped = dropped.dropFirst()
    }
}

func benchmark() {
    let lints = Array(repeating: { _ = 1 + 1 }, count: 100)
    
    print("🚀 Benchmarking Iteration Methods")
    
    measureExecutionTime(label: "Index-Based Iteration", iterations: iterations) {
        indexBasedExecution(lints: lints, iterations: lints.count)
    }
    
    measureExecutionTime(label: "DropFirst-Based Iteration", iterations: iterations) {
        dropFirstExecution(lints: lints, iterations: lints.count)
    }
}


// ✅ Run Execution Benchmark
@main
struct ExecutionBenchmarkApp {
    static func main() async {
        print("🚀 Starting Execution Benchmarks...")
        benchmark()
    }
}
