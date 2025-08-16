// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "JoyaaS",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "JoyaaS", targets: ["JoyaaS"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "JoyaaS",
            path: "Sources",
            exclude: [
                "README.md"
            ]
        )
    ]
)
