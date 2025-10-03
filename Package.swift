// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "AppStoreConnectKit",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
        .tvOS(.v18),
        .watchOS(.v11),
        .visionOS(.v2)
    ],
    products: [
        .library(
            name: "ConnectBagbutikFormatting",
            targets: ["ConnectBagbutikFormatting"]
        ),
        .library(
            name: "ConnectCore",
            targets: ["ConnectCore"]
        ),
        .library(
            name: "ConnectKeychain",
            targets: ["ConnectKeychain"]
        ),
        .library(
            name: "ConnectAccounts",
            targets: ["ConnectAccounts"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/MortenGregersen/Bagbutik", from: "18.1.0"),
    ],
    targets: [
        // ConnectBagbutikFormatting
        .target(name: "ConnectBagbutikFormatting", dependencies: [
            .product(name: "Bagbutik", package: "Bagbutik")
        ]),
        // ConnectCore
        .target(name: "ConnectCore", dependencies: ["ConnectBagbutikFormatting"]),
        .testTarget(name: "ConnectCoreTests", dependencies: ["ConnectCore"]),
        // ConnectKeychain
        .target(name: "ConnectKeychain", dependencies: ["ConnectCore"]),
        .testTarget(name: "ConnectKeychainTests", dependencies: ["ConnectKeychain"]),
        // ConnectAccounts
        .target(name: "ConnectAccounts", dependencies: [
            "ConnectKeychain",
            .product(name: "Bagbutik", package: "Bagbutik")
        ]),
        .testTarget(name: "ConnectAccountsTests", dependencies: ["ConnectAccounts"]),
    ]
)
