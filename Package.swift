// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Upcoming",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Upcoming", targets: ["Upcoming"])
    ],
    targets: [
        .executableTarget(
            name: "Upcoming",
            path: "Sources/Upcoming",
            exclude: ["Info.plist", "Upcoming.entitlements"]
        )
    ],
    swiftLanguageModes: [.v6]
)
