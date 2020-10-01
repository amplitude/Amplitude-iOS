// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Amplitude",
    platforms: [
        .iOS(.v10),
        .tvOS(.v9),
        .macOS(.v10_10)
    ],
    products: [
        .library(name: "Amplitude", targets: ["Amplitude"]),
    ],
    targets: [
        .target(
            name: "Amplitude",
            path: "Sources/Amplitude",
            exclude: [],
            sources: [".", "EventExplorer", "SSLPinning"],
            resources: [
                .process("EventExplorer/Resources")
            ],
            publicHeadersPath: ".")
    ]
)
