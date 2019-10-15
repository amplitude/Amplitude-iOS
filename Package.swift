// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Amplitude",
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
