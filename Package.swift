// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "input-store",
    platforms: [.macOS(.v11)],
    products: [
        .library(name: "InputStore", targets: ["InputStore"]),
    ],
    targets: [
        .target(name: "InputStore", dependencies: []),
    ]
)
