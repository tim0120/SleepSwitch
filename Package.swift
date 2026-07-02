// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SleepSwitch",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "SleepSwitch",
            path: "Sources/SleepSwitch"
        )
    ]
)
