import Combine
import ConnectCore
import ConnectKeychain
import Foundation

/// Controller for managing API keys stored in the keychain.
@Observable @MainActor
public class APIKeyController {
    /// The list of API keys.
    public private(set) var apiKeys: [APIKey]?
    /// The currently selected API key.
    ///
    /// Deprecated: The concept of a "selected API key" will be removed in a future version.
    /// Persist and manage selection state outside of APIKeyController.
    @available(*, deprecated, message: "The concept of a selected API key is deprecated and will be removed in a future version. Persist and manage selection outside of APIKeyController.")
    public var selectedAPIKey: APIKey? {
        didSet {
            if let selectedAPIKey {
                selectedAPIKeyId = selectedAPIKey.id
            }
        }
    }

    private let service: String
    private let keychain: KeychainProtocol
    private var selectedAPIKeyId: String? {
        get { UserDefaults.standard.string(forKey: "selected-api-key-id") }
        set { UserDefaults.standard.set(newValue, forKey: "selected-api-key-id") }
    }

    /**
     Initializes a new instance of `APIKeyController`.

     - Parameters:
        - keychainServiceName: The service name used for storing API keys in the keychain.
        - keychain: The Keychain instance to use for storing and retrieving API keys.
     */
    public init(keychainServiceName: String, keychain: KeychainProtocol) {
        precondition(!keychainServiceName.isEmpty, "Service must not be empty")
        self.service = keychainServiceName
        self.keychain = keychain
    }

    /// Loads the API keys from the keychain.
    ///
    /// Note: This method currently auto-selects an API key if one is available (matching the persisted selection, or the first key).
    /// The auto-selection side effect is deprecated and will be removed in a future version. Do not rely on it.
    public func loadAPIKeys() throws {
        let apiKeys = try keychain.listGenericPasswords(forService: service)
            .map { password -> APIKey in
                guard let apiKey = try? APIKey(password: password)
                else { throw APIKeyError.invalidAPIKeyFormat }
                return apiKey
            }
            .sorted { $0.name < $1.name }
        self.apiKeys = apiKeys
        if let apiKey = apiKeys.first(where: { $0.keyId == selectedAPIKeyId }) ?? apiKeys.first {
            selectedAPIKey = apiKey
        }
    }

    /**
     Adds a new API key to the keychain.

     - Parameter apiKey: The API key to add.

     Note: This method currently auto-selects the key if it is the first one added.
     The auto-selection side effect is deprecated and will be removed in a future version. Do not rely on it.
     */
    public func addAPIKey(_ apiKey: APIKey) throws {
        if apiKeys == nil {
            try loadAPIKeys()
        }
        do {
            try keychain.addGenericPassword(forService: service, password: apiKey.getGenericPassword())
        } catch KeychainError.duplicatePassword {
            throw APIKeyError.duplicateAPIKey
        } catch let KeychainError.failedAddingPassword(status) {
            throw APIKeyError.failedAddingAPIKey(status)
        }
        var apiKeys = apiKeys ?? []
        if apiKeys.isEmpty {
            selectedAPIKey = apiKey
        }
        apiKeys.append(apiKey)
        self.apiKeys = apiKeys.sorted(using: KeyPathComparator(\.name))
    }

    /**
     Deletes an API key from the keychain.

     - Parameter apiKey: The API key to delete.
     */
    public func deleteAPIKey(_ apiKey: APIKey) throws {
        if apiKeys == nil {
            try loadAPIKeys()
        }
        try keychain.deleteGenericPassword(forService: service, password: apiKey.getGenericPassword())
        guard var apiKeys, let index = apiKeys.firstIndex(where: { $0.keyId == apiKey.keyId }) else {
            return
        }
        apiKeys.remove(at: index)
        self.apiKeys = apiKeys
    }
}

public extension APIKeyController {
    /// An `APIKeyController` instance configured for use in previews and tests.
    static func forPreview(apiKeys: [APIKey]? = nil) -> APIKeyController {
        let controller = APIKeyController(keychainServiceName: "AppStoreConnectKit-Preview", keychain: Keychain.forPreview())
        controller.apiKeys = apiKeys
        return controller
    }
}
