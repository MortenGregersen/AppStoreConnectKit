import Foundation

/// Error happening when creating API Keys and adding them to Keychain.
public enum APIKeyError: LocalizedError, Equatable {
    /// The data for an API Key is invalid.
    case invalidAPIKeyFormat
    /// The API Key is already in Keychain.
    case duplicateAPIKey
    /// The API Key could not be added to Keychain. Lookup the status on <https://osstatus.com>.
    case failedAddingAPIKey(OSStatus)
    /// The API Key with the key ID was not found in Keychain.
    case apiKeyNotInKeychain(String)

    public var description: String {
        switch self {
        case .invalidAPIKeyFormat:
            "The data for an API Key is invalid"
        case .duplicateAPIKey:
            "The API Key is already in Keychain"
        case .failedAddingAPIKey(let status):
            "The API Key could not be added to Keychain (OSStatus: \(status)"
        case .apiKeyNotInKeychain(let keyId):
            "The API Key with the key ID '\(keyId)' was not found in Keychain."
        }
    }

    public var errorDescription: String? { description }
}
