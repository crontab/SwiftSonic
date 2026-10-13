// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "SwiftSonic",
    platforms: [
        .iOS(.v18),
        .macOS(.v15)
    ],

    products: [
        .library(
            name: "CSonic",
            targets: ["CSonic"]
        ),
    ],

    targets: [

        // MARK: - CSonic

        .target(
            name: "CSonic",
            publicHeadersPath: "include"
        ),
    ]
)
