// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "Upcoming",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "Upcoming",
            path: "Sources/Upcoming",
            exclude: ["Info.plist"]
        )
    ]
)
