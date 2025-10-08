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
        .library(name: "ConnectBagbutikFormatting", targets: ["ConnectBagbutikFormatting"]),
        .library(name: "ConnectCore", targets: ["ConnectCore"]),
        .library(name: "ConnectKeychain", targets: ["ConnectKeychain"]),
        .library(name: "ConnectAccounts", targets: ["ConnectAccounts"]),
        .library(name: "ConnectClient", targets: ["ConnectClient"]),
        .library(name: "ConnectProvisioning", targets: ["ConnectProvisioning"]),
    ],
    dependencies: [
        .package(url: "https://github.com/MortenGregersen/Bagbutik", from: "18.1.0"),
        .package(url: "https://github.com/cbaker6/CertificateSigningRequest", from: "1.30.0"),
    ],
    targets: [
        // ConnectBagbutikFormatting
        .target(name: "ConnectBagbutikFormatting", dependencies: [.product(name: "Bagbutik", package: "Bagbutik")]),
        .target(name: "ConnectTestSupport", dependencies: ["ConnectKeychain", "ConnectClient"]),
        // ConnectCore
        .target(name: "ConnectCore", dependencies: ["ConnectBagbutikFormatting"]),
        .testTarget(name: "ConnectCoreTests", dependencies: ["ConnectCore"]),
        // ConnectKeychain
        .target(name: "ConnectKeychain", dependencies: ["ConnectCore"]),
        .testTarget(name: "ConnectKeychainTests", dependencies: ["ConnectKeychain"]),
        // ConnectAccounts
        .target(name: "ConnectAccounts", dependencies: ["ConnectKeychain", .product(name: "Bagbutik", package: "Bagbutik")]),
        .testTarget(name: "ConnectAccountsTests", dependencies: ["ConnectAccounts", "ConnectTestSupport"]),
        // ConnectClient
        .target(name: "ConnectClient", dependencies: [.product(name: "Bagbutik", package: "Bagbutik")]),
        // ConnectProvisioning
        .target(name: "ConnectProvisioning", dependencies: [
            "ConnectClient",
            "ConnectKeychain",
            "CertificateSigningRequest",
            .product(name: "Bagbutik", package: "Bagbutik")
        ]),
        .testTarget(name: "ConnectProvisioningTests", dependencies: ["ConnectProvisioning", "ConnectTestSupport"]),
    ]
)
