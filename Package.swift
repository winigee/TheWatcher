// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TheWatcher",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "TheWatcher",
            path: "Sources/TheWatcher"
        ),
        .testTarget(
            name: "TheWatcherTests",
            dependencies: ["TheWatcher"],
            path: "Tests/TheWatcherTests"
        )
    ]
)
