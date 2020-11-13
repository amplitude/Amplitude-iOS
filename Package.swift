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
            name: "EventExplorer",
            path: "Sources/EventExplorer",
            resources: [
                .process("Resources/AMPBubbleView.xib"),
                .process("Resources/AMPInfoViewController.xib"),
                .process("Resources/Images/cancel.png"),
                .process("Resources/Images/cancel@2x.png"),
                .process("Resources/Images/cancel@3x.png"),
                .process("Resources/Images/logo-banner.png"),
                .process("Resources/Images/logo-banner@2x.png"),
                .process("Resources/Images/logo-banner@3x.png"),
                .process("Resources/Images/logo-button.png"),
                .process("Resources/Images/logo-button@2x.png"),
                .process("Resources/Images/logo-button@3x.png")
            ],
            publicHeadersPath: ".",
            cSettings: [
                .headerSearchPath("../Amplitude")
            ]
          ),
          .target(
            name: "Amplitude",
             dependencies: [
                .target(name: "EventExplorer", condition: .when(platforms: [.iOS])),
            ],
            path: "Sources/Amplitude",
            resources: [.process("Resources/ComodoRsaDomainValidationCA.der")],
            publicHeadersPath: "."),
    ]
)