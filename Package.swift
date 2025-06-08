// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "WNBASchedule",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "WNBASchedule", targets: ["WNBASchedule"])
    ],
    dependencies: [
        .package(url: "https://github.com/malcommac/SwiftDate.git", from: "6.3.1"),
        .package(url: "https://github.com/sindresorhus/LaunchAtLogin-Modern", from: "1.0.0"),
        .package(url: "https://github.com/realm/SwiftLint", from: "0.52.0"),
    ],
    targets: [
        .executableTarget(
            name: "WNBASchedule",
            dependencies: [
                "SwiftDate",
                .product(name: "LaunchAtLogin", package: "LaunchAtLogin-Modern")
            ]),
        .testTarget(
            name: "WNBAScheduleTests",
            dependencies: ["WNBASchedule"]),
    ]
)