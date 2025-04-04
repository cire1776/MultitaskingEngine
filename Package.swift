// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MultitaskingEngine",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "MultitaskingEngine",
            targets: ["MultitaskingEngine", "PointerUtilities"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-atomics.git", from: "1.0.0"),
        .package(url: "https://github.com/Quick/Quick.git", from: "7.0.0"),
        .package(url: "https://github.com/Quick/Nimble.git", exact: "13.0.0"),
//        .package(name: "ULangLib", path: "../")
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
                "PointerUtilities"
            ],
            path: "Tests/MultitaskingEngineTests",
//            sources: [
//                "Enitities",
//            ],
            linkerSettings: [
                .linkedFramework("XCTest") // ✅ Explicitly link XCTest
            ],        ),
    ]
)
