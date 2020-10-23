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
            name: "AmplitudeEventExplorer",
            path: "Sources/Amplitude",
            sources: [
              "AMPBubbleView.m",
              "AMPEventExplorer.m",
              "AMPInfoViewController.m",
              "AMPBubbleView.h",
              "AMPEventExplorer.h",
              "AMPInfoViewController.h"
            ],
            resources: [
                .process("Resources/AMPBubbleView.xib"),
                .process("Resources/AMPInfoViewController.xib"),
                .process("Resources/cancel.png"),
                .process("Resources/cancel@2x.png"),
                .process("Resources/cancel@3x.png"),
                .process("Resources/ComodoRsaDomainValidationCA.der"),
                .process("Resources/logo-banner.png"),
                .process("Resources/logo-banner@2x.png"),
                .process("Resources/logo-banner@3x.png"),
                .process("Resources/logo-button.png"),
                .process("Resources/logo-button@2x.png"),
                .process("Resources/logo-button@3x.png")
            ],
            publicHeadersPath: "."),
          .target(
            name: "AmplitudeCore",
            path: "Sources/Amplitude",
            exclude: [
              "AMPBubbleView.m",
              "AMPEventExplorer.m",
              "AMPInfoViewController.m",
              "AMPBubbleView.h",
              "AMPEventExplorer.h",
              "AMPInfoViewController.h"
            ],
            sources: ["."],
            publicHeadersPath: "."),
          .target(
              name: "Amplitude",
              dependencies: [
                .target(name: "AmplitudeEventExplorer", condition: .when(platforms: [.iOS])),
                // .target(name: "AmplitudeEventExplorer"),
                .target(name: "AmplitudeCore")
              ]
          )
    ]
)