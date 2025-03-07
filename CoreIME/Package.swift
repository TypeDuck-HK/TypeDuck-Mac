// swift-tools-version: 6.0

import PackageDescription

let package = Package(
        name: "CoreIME",
        platforms: [.macOS(.v12)],
        products: [
                .library(
                        name: "CoreIME",
                        targets: ["CoreIME"]
                )
        ],
        targets: [
                .target(
                        name: "CoreIME",
                        resources: [.process("Resources")]
                ),
                .testTarget(
                        name: "CoreIMETests",
                        dependencies: ["CoreIME"]
                )
        ]
)
