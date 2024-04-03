// swift-tools-version: 5.10

import PackageDescription

let package = Package(
        name: "Preparing",
        platforms: [.macOS(.v14)],
        products: [.executable(name: "Preparing", targets: ["Preparing"])],
        targets: [
                .executableTarget(
                        name: "Preparing",
                        path: "Sources/Preparing",
                        resources: [.process("Resources")]
                )
        ]
)
