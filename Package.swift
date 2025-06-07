// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "WNBASchedule",
    platforms: [
        .macOS(.v12) // SwiftUI requires macOS 10.15+, but we're already requiring macOS 12
    ],
    products: [
        .executable(name: "WNBASchedule", targets: ["WNBASchedule"])
    ],
    dependencies: [
        .package(url: "https://github.com/malcommac/SwiftDate.git", from: "6.3.1"),
    ],
    targets: [
        .executableTarget(
            name: "WNBASchedule",
            dependencies: [
                "SwiftDate"
            ],
            resources: [
                .process("Resources")
            ]),
        .testTarget(
            name: "WNBAScheduleTests",
            dependencies: ["WNBASchedule"]),
    ]
)