// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "mimiq",
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", .upToNextMinor(from: "0.0.1")),
        .package(url: "https://github.com/wendyliga/ConsoleIO.git", .upToNextMajor(from: "1.0.0")),
        .package(url: "https://github.com/wendyliga/Explorer.git", from: "0.0.3"),
    ],
    targets: [
        .target(
            name: "mimiq",
            dependencies: ["ArgumentParser", "Explorer", "ConsoleIO"]
        ),
        .testTarget(
            name: "mimiqTests",
            dependencies: ["mimiq"]),
    ]
)
