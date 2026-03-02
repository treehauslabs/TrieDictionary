// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "TrieDictionary",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6),
    ],
    products: [
        .library(
            name: "TrieDictionary",
            targets: ["TrieDictionary"]),
    ],
    dependencies: [
        // No external dependencies - pure Swift implementation
    ],
    targets: [
        .target(
            name: "TrieDictionary",
            dependencies: [],
            swiftSettings: [
                .define("SWIFT_PACKAGE")
            ]),
        .testTarget(
            name: "TrieDictionaryTests",
            dependencies: ["TrieDictionary"]),
    ]
)
