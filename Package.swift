// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "LocalStray",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "LocalStray",
            targets: ["LocalStray"]
        ),
        .executable(
            name: "LocalStrayCommandHelper",
            targets: ["LocalStrayCommandHelper"]
        ),
        .library(
            name: "LocalStrayCommandProtocol",
            targets: ["LocalStrayCommandProtocol"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/sparkle-project/Sparkle",
            exact: "2.9.3"
        ),
        .package(
            url: "https://github.com/modelcontextprotocol/swift-sdk.git",
            exact: "0.12.1"
        ),
        .package(
            url: "https://github.com/adriancmurray/swift-mcp-router.git",
            exact: "0.1.0"
        )
    ],
    targets: [
        .executableTarget(
            name: "LocalStray",
            dependencies: [
                "LocalStrayCommandProtocol",
                "LocalStrayCommandCore",
                .product(name: "MCP", package: "swift-sdk"),
                .product(name: "SwiftMCPStore", package: "swift-mcp-router"),
                .product(name: "Sparkle", package: "Sparkle")
            ],
            path: "Sources/LocalStray",
            resources: [
                .process("../../Resources")
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .target(
            name: "LocalStrayCommandProtocol",
            path: "Sources/LocalStrayCommandProtocol",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .target(
            name: "LocalStrayCommandCore",
            dependencies: ["LocalStrayCommandProtocol"],
            path: "Sources/LocalStrayCommandCore",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .executableTarget(
            name: "LocalStrayCommandHelper",
            dependencies: ["LocalStrayCommandProtocol", "LocalStrayCommandCore"],
            path: "Sources/LocalStrayCommandHelper",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "LocalStrayTests",
            dependencies: ["LocalStray"],
            path: "Tests/LocalStrayTests",
            linkerSettings: [
                .unsafeFlags([
                    "-Xlinker", "-rpath",
                    "-Xlinker", "@loader_path/../../.."
                ])
            ]
        ),
        .testTarget(
            name: "LocalStrayCommandCoreTests",
            dependencies: ["LocalStrayCommandProtocol", "LocalStrayCommandCore"],
            path: "Tests/LocalStrayCommandCoreTests"
        )
    ]
)
