<p align="center">
    <br />
    <img src="https://raw.githubusercontent.com/MortenGregersen/AppStoreConnectKit/master/Assets/AppStoreConnectKit-logo.png" width="400" max-width="90%" alt="AppStoreConnectKit logo" />
</p>
<h1 align="center">AppStoreConnectKit</h1>

<p align="center">
    <b>All you need to interact with the <a href="https://developer.apple.com/documentation/appstoreconnectapi">App Store Connect API</a> on Apple platforms.</b>
    <br /><br />
    <a href="https://swiftpackageindex.com/MortenGregersen/AppStoreConnectKit"><img src="https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FMortenGregersen%2FAppStoreConnectKit%2Fbadge%3Ftype%3Dswift-versions" alt="Swift versions" /></a>
    <a href="https://swiftpackageindex.com/MortenGregersen/AppStoreConnectKit"><img src="https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FMortenGregersen%2FAppStoreConnectKit%2Fbadge%3Ftype%3Dplatforms" alt="Platforms" /></a>
    <br />
    <a href="https://github.com/MortenGregersen/AppStoreConnectKit/actions/workflows/ci.yml"><img src="https://github.com/MortenGregersen/AppStoreConnectKit/actions/workflows/ci.yml/badge.svg" alt="CI" /></a>
    <br />
    <a href="https://x.com/mortengregersen"><img src="https://img.shields.io/badge/%40mortengregersen-black?logo=x" alt="X (Twitter)" /></a>
    <a href="https://mastodon.social/@mortengregersen"><img src="https://img.shields.io/badge/%40mortengregersen-6364FF?logo=mastodon&logoColor=white" alt="Mastodon" /></a>
</p>

## What is AppStoreConnectKit?

With **AppStoreConnectKit**, you have all you need to interact with the **App Store Connect API** on Apple platforms. With the `APIKeyController` you can handle `APIKey`s stored in Keychain, and with the `AppStoreConnectClient`, you can perform all the operations in the API.

These libraries are born out of code coming from [AppDab for App Store Connect](https://AppDab.app), which is now based on AppStoreConnectKit. AppDab is the fastest way to ship your apps on the App Store 🚀

### How do I create an API Key?

An API Key is created in App Store Connect and consists of a Key ID and a Private Key (.p8 file).

With the `GenerateAPIKeyView`, you can present a SwiftUI View for the user, that guides them through creating an API Key with steps and visual guidance on the website. When the user has created the API Key, copied the Key ID and clicked the "Download API Key" button, your custom validation logic is run, and you get the values in a callback.

> You can read more about [Creating API Keys for App Store Connect API](https://developer.apple.com/documentation/appstoreconnectapi/creating_api_keys_for_app_store_connect_api) in Apple's documentation.

## Getting Started

### Installation
Add this package to your `Package.swift` dependencies:

```
.package(url: "https://github.com/mortengregersen/appstoreconnectkit.git", from: "0.1.0")
```

## Libraries

Here are the libraries in the package and their roles:

- **ConnectCore**: Shared types and logic to parse errors from the App Store Connect API.
- **ConnectKeychain**: Handles Keychain operations on-device: storing API keys, certificates.
- **ConnectAccounts**: Manages named API keys stored in Keychain.
- **ConnectAccountsUI**: SwiftUI views for generating API Keys via a webview, guiding the user.
- **ConnectClient**: Provides an `@Observable` wrapper around Bagbutik’s service layer — useful with SwiftUI's @Environment.
- **ConnectProvisioning**: Workflow for creating certificates (via ConnectClient) and storing them (via ConnectKeychain).
- **ConnectBagbutikFormatting**: Provides formatted string names (e.g., case names) for Bagbutik enums or types.

### Error Handling

The `ConnectCore` library contains logic to parse errors coming from the App Store Connect API.

## Apps Using AppStoreConnectKit
- **AppDab** — A macOS/iOS tool for App Store metadata and TestFlight management. This app uses AppStoreConnectKit to manage API Keys, store them securely, and drive API calls.

## Contributing
Contributions are very welcome!
- Report issues or feature-requests via GitHub Issues.
- Pull requests: ensure code is formatted, tests pass, and interfaces remain backward-compatible (or version them).

## Contact
Feel free to open issues, suggest enhancements or explain how you’re using this package.

Happy coding 🎉
