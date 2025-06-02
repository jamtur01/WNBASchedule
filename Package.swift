// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "WNBASchedule",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(name: "WNBASchedule", targets: ["WNBASchedule"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "WNBASchedule",
            dependencies: [],
            resources: [
                .process("Resources")
            ]),
        .testTarget(
            name: "WNBAScheduleTests",
            dependencies: ["WNBASchedule"]),
    ]
)