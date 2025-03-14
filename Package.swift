// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MultitaskingEngine",
    platforms: [
        .macOS(.v15) // ✅ Set to macOS 12 to avoid 15.0 restriction issues
    ],
    products: [
        .library(
            name: "MultitaskingEngine",
            targets: ["MultitaskingEngine", "PointerUtilities"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-atomics.git", from: "1.0.0"),
        .package(url: "https://github.com/Quick/Quick.git", from: "7.0.0"),
        .package(url: "https://github.com/Quick/Nimble.git", exact: "13.0.0"),
        .package(name: "ULangLib", path: "../")  // ✅ Ensure this path is correct
    ],
    targets: [
        .target(
            name: "MultitaskingEngine",
            dependencies: [
                "PointerUtilities",
                .product(name: "Atomics", package: "swift-atomics")
            ],
            path: "Sources/MultitaskingEngine"
        ),
        .target(
            name: "PointerUtilities",
            path: "CSources/PointerUtilities",
            exclude: [],
            sources: ["pointer_utilities.c"],
            publicHeadersPath: "include"
        ),
        .target(
            name: "TestHelpers",
            dependencies: ["MultitaskingEngine", "PointerUtilities"],
            path: "Sources/TestHelpers"
        ),
        .testTarget(
            name: "MultitaskingEngineTests",
            dependencies: [
                "MultitaskingEngine",
                "Quick",
                "Nimble",
                "TestHelpers",
                "PointerUtilities",
                "ULangLib"
            ],
            path: "Tests/MultitaskingEngineTests", linkerSettings: [
                .linkedFramework("XCTest") // ✅ Explicitly link XCTest
            ]
        ),
    ]
)
