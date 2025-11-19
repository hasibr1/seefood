// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SeeFood",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "SeeFood",
            targets: ["SeeFood"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.2.2")
    ],
    targets: [
        .target(
            name: "SeeFood",
            dependencies: ["KeychainAccess"]
        ),
        .testTarget(
            name: "SeeFoodTests",
            dependencies: ["SeeFood"]
        ),
    ]
)