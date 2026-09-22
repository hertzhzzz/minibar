// swift-tools-version:6.4
import PackageDescription

let package = Package(
    name: "MiniBar",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "MiniBar",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("SwiftUI")
            ]
        ),
        .testTarget(
            name: "MiniBarTests",
            dependencies: ["MiniBar"]
        )
    ]
)
