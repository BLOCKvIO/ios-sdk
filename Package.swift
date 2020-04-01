// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BLOCKv",
    platforms: [
        .iOS(.v11)
    ],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "BLOCKv",
            targets: ["BLOCKv"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire", from: "4.9.0"),
        .package(url: "https://github.com/daltoniam/Starscream", from: "3.1.1"),
        .package(url: "https://github.com/kean/Nuke", from: "8.4.1"),
        .package(url: "https://github.com/mxcl/PromiseKit", from: "6.13.1"),
        .package(url: "https://github.com/auth0/JWTDecode.swift", from: "2.4.1"),
        .package(url: "https://github.com/artman/Signals", from: "6.1.0"),
        .package(url: "https://github.com/zoul/generic-json-swift", from: "2.0.1"),
        .package(url: "https://github.com/realm/SwiftLint", from: "0.39.1"),
        .package(url: "https://github.com/sonsongithub/FLAnimatedImageSPM", .revision("a4aa45188e09e951b57bed19ff2b4cb900d93289")),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "BLOCKv",
            dependencies: ["Alamofire", "Starscream", "Nuke", "Signals", "PromiseKit", "JWTDecode", "GenericJSON", "FLAnimatedImage"],
            path: "Sources"),
        .testTarget(
            name: "BLOCKv-Unit-Tests",
            dependencies: ["BLOCKv"]),
    ],
    swiftLanguageVersions: [
        .v5
    ]
)
