// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SwiftBenchmarks",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        // ✅ Shared Library to be used by multiple benchmarks
        .library(name: "Shared", targets: ["Shared"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-atomics.git", from: "1.0.0"),
    ],
    targets: [
        // ✅ Shared Target for Common Code
        .target(
            name: "Shared",
            dependencies: ["CQueue", "CVariableStore"],
            path: "Sources/Shared",
            sources: ["BenchmarkUtils.swift", "CircularQueueWrapper.swift", "VariableStoreWrapper.swift"],
            swiftSettings: [.define("ENABLE_TESTING")]  // ✅ Allows `@testable import`
        ),

        // ✅ SwitchVsClosure Benchmark (Uses `Shared`)
        .executableTarget(
            name: "SwitchVsClosureBenchmark",
            dependencies: [
                "CQueue", "CVariableStore", "Shared",
                .product(name: "Atomics", package: "swift-atomics")
            ],
            path: "Sources/SwitchVsClosureBenchmark",
            sources: ["mainentry.swift"]
        ),

        .executableTarget(
            name: "ResetStreamVsOptions",
            dependencies: [
              "CQueue", "Shared",
              .product(name: "Atomics", package: "swift-atomics")
            ],
            path: "Sources/ResetStreamVsOptions",
            sources: ["streamEntry.swift"]
        ),

       // ✅ Variable Lookup Benchmark (Uses `Shared`)
        .executableTarget(
            name: "VariableLookupBenchmark",
            dependencies: [
                "CQueue", "CVariableStore", "Shared",
                .product(name: "Atomics", package: "swift-atomics")
            ],
            path: "Sources/VariableLookupBenchmark",
            sources: ["main.swift"]
        ),


        // ✅ Placeholder for Additional Benchmarks
        .executableTarget(
            name: "SliceVsIndexingBenchmark",
            dependencies: [
                "CQueue", "CVariableStore", "Shared",
                .product(name: "Atomics", package: "swift-atomics")
            ],
            path: "Sources/SliceVsIndexingBenchmark",
            sources: ["sliceentry.swift"]
        ),

        // ✅ Placeholder for Additional Benchmarks
        .executableTarget(
            name: "OtherBenchmarks",
            dependencies: [],
            path: "Sources/OtherBenchmarks"
        ),

        // ✅ C Module Target for Circular Queue
        .target(
            name: "CQueue",
            path: "CQueue",
            sources: ["circular_queue.c", "circular_queue_bridge.c"],
            publicHeadersPath: "include"
        ),

        // ✅ C Module Target for Variable Store
        .target(
            name: "CVariableStore",
            path: "CVariableStore",
            sources: ["c_variable_store_bridge.c", "c_variable_store.c"],
            publicHeadersPath: "include"
        ),
        // ✅ Unit Tests
        .testTarget(
            name: "SwiftBenchmarksTests",
            dependencies: ["SwitchVsClosureBenchmark"],
            path: "Tests/SwiftBenchmarksTests"
        )
    ]
)
