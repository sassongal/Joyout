// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "JoyaaSMenuBar",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "JoyaaSMenuBar", targets: ["JoyaaSMenuBar"])
    ],
    targets: [
        .executableTarget(
            name: "JoyaaSMenuBar",
            path: "JoyaaSMenuBar",
            exclude: ["JoyaaSMenuBar.entitlements"],
            resources: [
                .process("Assets.xcassets"),
                .process("menubar-icon.png")
            ]
        )
    ]
)
