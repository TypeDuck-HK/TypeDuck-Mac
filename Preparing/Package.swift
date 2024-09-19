// swift-tools-version: 6.0

import PackageDescription

let package = Package(
        name: "Preparing",
        platforms: [.macOS(.v15)],
        products: [.executable(name: "Preparing", targets: ["Preparing"])],
        targets: [
                .executableTarget(
                        name: "Preparing",
                        path: "Sources/Preparing",
                        resources: [.process("Resources")]
                )
        ]
)
