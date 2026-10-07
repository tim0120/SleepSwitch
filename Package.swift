// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SleepSwitch",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .target(name: "SleepSwitchCore"),
        .target(name: "SleepSwitchIcon"),
        .executableTarget(
            name: "SleepSwitch",
            dependencies: ["SleepSwitchCore", "SleepSwitchIcon"],
            path: "Sources/SleepSwitch"
        )
    ]
)
