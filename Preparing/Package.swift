// swift-tools-version: 5.9

import PackageDescription

let package = Package(
        name: "Preparing",
        platforms: [.macOS(.v13)],
        products: [.executable(name: "prepare", targets: ["Preparing"])],
        targets: [
                .executableTarget(
                        name: "Preparing",
                        path: "Sources/Preparing",
                        resources: [.process("Resources")]
                )
        ]
)
