import Foundation
import Atomics
import Dispatch
import Shared

let iterations = 1_000_000  // ✅ Global iteration count

final class Counter {
    var value: Int = 0

    @inline(never)
    func makeCapturingClosures() -> [() -> Int] {
        return (1...5).map { i in
            return {
                self.value += i
                return i
            }
        }
    }

    @inline(never)
    func makeUnownedCapturingClosures() -> [() -> Int] {
        return (1...5).map { i in
            return { [unowned self] in
                self.value += i
                return i
            }
        }
    }
}

final class CounterA {
    var value: Int = 0

    func reset() {
        value = 0
    }
}

func benchmark() {
    print("🚀 Running Execution Benchmarks with \(formatNumber(Double(iterations))) iterations...")

    // ✅ Closure Call Overhead Benchmark
    let closureArray: [() -> Int] = [
        { return 1 }, { return 2 }, { return 3 }, { return 4 }, { return 5 }
    ]
    var closureResult = 0
    measureExecutionTime(label: "Closure Call Overhead", iterations: iterations) {
        for i in 0..<iterations {
            closureResult += closureArray[i % closureArray.count]()
        }
    }
    print("🔥 Final Closure Result:", formatNumber(Double(closureResult)))

    let externalCounter = CounterA()
     let counterInstance = CounterA()

     // 1️⃣ External Capture (outside closure)
     let externalClosures: [() -> Int] = [
         { externalCounter.value += 1; return 1 },
         { externalCounter.value += 2; return 2 },
         { externalCounter.value += 3; return 3 },
         { externalCounter.value += 4; return 4 },
         { externalCounter.value += 5; return 5 }
     ]

     var result = 0
     externalCounter.reset()
     measureExecutionTime(label: "External Counter Capturing", iterations: iterations) {
         for i in 0..<iterations {
             result += externalClosures[i % externalClosures.count]()
         }
     }
     print("🔥 Final External Counter Result: \(result)")
     print("🔥 External Counter.value: \(externalCounter.value)")
     print("")

    // ✅ Closure (Capturing self)
    let counter1 = Counter()
    let capturingClosures = counter1.makeCapturingClosures()
    var capturingResult = 0

    measureExecutionTime(label: "Closure Capturing self", iterations: iterations) {
        for i in 0..<iterations {
            capturingResult += capturingClosures[i % capturingClosures.count]()
        }
    }
    print("🔥 Final Capturing Result:", capturingResult)
    blackhole(counter1.value)

    let counter2 = Counter()
    let unownedClosures = counter2.makeUnownedCapturingClosures()
    var unownedResult = 0

    measureExecutionTime(label: "Closure Capturing [unowned self]", iterations: iterations) {
        for i in 0..<iterations {
            unownedResult += unownedClosures[i % unownedClosures.count]()
        }
    }
    print("🔥 Final Unowned Capturing Result:", unownedResult)
    blackhole(counter2.value)
              
    // ✅ Function Pointer Lookup Benchmark
    func op1() -> Int { return 1 }
    func op2() -> Int { return 2 }
    func op3() -> Int { return 3 }
    func op4() -> Int { return 4 }
    func op5() -> Int { return 5 }
    let functionPointers: [() -> Int] = [op1, op2, op3, op4, op5]
    
    var functionResult = 0
    measureExecutionTime(label: "Function Pointer Lookup", iterations: iterations) {
        for i in 0..<iterations {
            functionResult += functionPointers[i % functionPointers.count]()
        }
    }
    print("🔥 Final Function Pointer Result:", formatNumber(Double(functionResult)))

    // ✅ Switch Case Execution Benchmark
    var switchCounter = 0
    measureExecutionTime(label: "Switch Case Execution with Random Numbers", iterations: iterations) {
        for _ in 0..<iterations {
            let value = Int.random(in: 0...9)
            switch value {
            case 0...9:
                switchCounter += value
            default:
                fatalError("Unexpected case")
            }
        }
    }
    print("🔥 Final Switch Counter:", formatNumber(Double(switchCounter)))

    // ✅ Enum-Based Dispatch Benchmark
    enum Operation { case op1, op2, op3, op4, op5 }
    let enumOperations: [Operation] = [.op1, .op2, .op3, .op4, .op5]

    var enumCounter = 0
    measureExecutionTime(label: "Enum-Based Dispatch with Random Numbers", iterations: iterations) {
        for _ in 0..<iterations {
            let op = enumOperations.randomElement()!
            switch op {
            case .op1: enumCounter += 1
            case .op2: enumCounter += 2
            case .op3: enumCounter += 3
            case .op4: enumCounter += 4
            case .op5: enumCounter += 5
            }
        }
    }
    print("🔥 Final Enum Counter:", formatNumber(Double(enumCounter)))
}

// ✅ Run Execution Benchmark
@main
struct ExecutionBenchmarkApp {
    static func main() async {
        print("🚀 Starting Execution Benchmarks...")
        benchmark()
    }
}
