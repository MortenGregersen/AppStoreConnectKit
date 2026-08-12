// swift-tools-version:6.1

import PackageDescription

let bagbutikCoreDependencies: [Target.Dependency] = [
    .product(name: "BagbutikCore", package: "Bagbutik-Binary"),
]

let bagbutikAppStoreDependencies = bagbutikCoreDependencies + [
    .product(name: "BagbutikAppStore", package: "Bagbutik-Binary"),
]

let bagbutikProvisioningDependencies = bagbutikAppStoreDependencies + [
    .product(name: "BagbutikProvisioning", package: "Bagbutik-Binary"),
]

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
        .library(name: "ConnectCore", targets: ["ConnectCore"]),
        .library(name: "ConnectKeychain", targets: ["ConnectKeychain"]),
        .library(name: "ConnectAccounts", targets: ["ConnectAccounts"]),
        .library(name: "ConnectAccountsUI", targets: ["ConnectAccountsUI"]),
        .library(name: "ConnectClient", targets: ["ConnectClient"]),
        .library(name: "ConnectProvisioning", targets: ["ConnectProvisioning"]),
        .library(name: "ConnectBagbutikFormatting", targets: ["ConnectBagbutikFormatting"]),
    ],
    dependencies: [
        .package(url: "https://github.com/MortenGregersen/Bagbutik-Binary", exact: "24.0.0-pre5"),
        .package(url: "https://github.com/cbaker6/CertificateSigningRequest", from: "1.30.0"),
    ],
    targets: [
        // ConnectCore
        .target(name: "ConnectCore", dependencies: bagbutikAppStoreDependencies + ["ConnectBagbutikFormatting"]),
        .testTarget(name: "ConnectCoreTests", dependencies: bagbutikAppStoreDependencies + ["ConnectCore"]),
        // ConnectKeychain
        .target(name: "ConnectKeychain", dependencies: ["ConnectCore"]),
        .testTarget(name: "ConnectKeychainTests", dependencies: ["ConnectKeychain"]),
        // ConnectAccounts
        .target(name: "ConnectAccounts", dependencies: bagbutikCoreDependencies + ["ConnectKeychain"]),
        .testTarget(name: "ConnectAccountsTests", dependencies: bagbutikCoreDependencies + ["ConnectAccounts", "ConnectTestSupport"]),
        // ConnectAccountsUI
        .target(name: "ConnectAccountsUI", dependencies: bagbutikCoreDependencies + ["ConnectAccounts"]),
        // ConnectClient
        .target(name: "ConnectClient", dependencies: bagbutikCoreDependencies),
        .testTarget(name: "ConnectClientTests", dependencies: bagbutikCoreDependencies + ["ConnectClient", "ConnectTestSupport"]),
        // ConnectProvisioning
        .target(name: "ConnectProvisioning", dependencies: [
            "ConnectClient",
            "ConnectKeychain",
            "CertificateSigningRequest",
        ] + bagbutikProvisioningDependencies),
        .testTarget(name: "ConnectProvisioningTests", dependencies: bagbutikProvisioningDependencies + ["ConnectProvisioning", "ConnectTestSupport"]),
        // ConnectBagbutikFormatting
        .target(name: "ConnectBagbutikFormatting", dependencies: bagbutikAppStoreDependencies),
        // ConnectTestSupport
        .target(name: "ConnectTestSupport", dependencies: bagbutikCoreDependencies + ["ConnectKeychain", "ConnectClient"]),
    ]
)
