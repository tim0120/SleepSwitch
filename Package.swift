// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SleepSwitch",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .target(name: "SleepSwitchCore"),
        .executableTarget(
            name: "SleepSwitch",
            dependencies: ["SleepSwitchCore"],
            path: "Sources/SleepSwitch"
        )
    ]
)
