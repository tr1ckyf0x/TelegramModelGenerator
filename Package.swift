// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TelegramModelGenerator",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "telegram-model-generator",
            targets: ["TelegramModelGenerator"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", exact: "1.3.0"),
        .package(url: "https://github.com/scinfu/SwiftSoup", from: "2.6.0"),
        .package(url: "https://github.com/Alamofire/Alamofire", .upToNextMajor(from: "5.8.1")),
        .package(url: "https://github.com/Quick/Quick", from: "7.0.0"),
        .package(url: "https://github.com/Quick/Nimble", from: "13.0.0")
    ],
    targets: [
        .executableTarget(
            name: "TelegramModelGenerator",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "SwiftSoup", package: "SwiftSoup"),
                .product(name: "Alamofire", package: "Alamofire")
            ]
        ),
        .testTarget(
            name: "TelegramModelGeneratorTests",
            dependencies: [
                "TelegramModelGenerator",
                "Quick",
                "Nimble"
            ]
        )
    ]
)
