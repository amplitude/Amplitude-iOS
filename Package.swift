// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Amplitude",
    platforms: [.macOS(.v10_10),
                .iOS(.v10),
                .tvOS(.v10)],
    products: [
        .library(
            name: "Amplitude",
            targets: ["Amplitude"]),
    ],
    targets: [
        .target(
            name: "Amplitude",
            path: "Sources",
            exclude: [],
            sources: ["Amplitude", "Amplitude/"],
            publicHeadersPath: "Amplitude"),
    ]
)
