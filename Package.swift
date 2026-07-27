// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Booster",
    platforms: [
        .macOS(.v13),
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "Booster",
            targets: ["Booster"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.58.0"),
        .package(url: "https://github.com/vapor/vapor.git", from: "4.83.0"),
    ],
    targets: [
        .target(
            name: "Booster",
            dependencies: [
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "Vapor", package: "vapor"),
            ],
            path: "services/swift"
        ),
        .testTarget(
            name: "BoosterTests",
            dependencies: ["Booster"],
            path: "tests/swift"
        ),
    ]
)
