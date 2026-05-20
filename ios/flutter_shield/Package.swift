// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "flutter_shield",
    platforms: [
        .iOS(.v12),
    ],
    products: [
        .library(name: "flutter_shield", targets: ["flutter_shield"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "flutter_shield",
            dependencies: [],
            path: "Sources/flutter_shield"
        )
    ]
)
