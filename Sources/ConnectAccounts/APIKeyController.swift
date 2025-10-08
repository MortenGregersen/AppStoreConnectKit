import Combine
import ConnectCore
import ConnectKeychain
import Foundation

@Observable @MainActor
public class APIKeyController {
    public private(set) var apiKeys: [APIKey]?
    public var selectedAPIKey: APIKey? {
        didSet {
            if let selectedAPIKey {
                selectedAPIKeyId = selectedAPIKey.id
            }
        }
    }

    public var didAddAPIKey: PassthroughSubject<APIKey, Never> = .init()
    public var didDeleteAPIKey: PassthroughSubject<APIKey, Never> = .init()

    private let service: String
    private let keychain: KeychainProtocol
    private var selectedAPIKeyId: String? {
        get { UserDefaults.standard.string(forKey: "selected-api-key-id") }
        set { UserDefaults.standard.set(newValue, forKey: "selected-api-key-id") }
    }

    public init(keychainServiceName: String, keychain: KeychainProtocol) {
        precondition(!keychainServiceName.isEmpty, "Service must not be empty")
        self.service = keychainServiceName
        self.keychain = keychain
    }

    public func loadAPIKeys() async throws {
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

    public func addAPIKey(_ apiKey: APIKey) throws {
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
        self.apiKeys = apiKeys
        didAddAPIKey.send(apiKey)
    }

    public func deleteAPIKey(_ apiKey: APIKey) throws {
        try keychain.deleteGenericPassword(forService: service, password: apiKey.getGenericPassword())
        guard var apiKeys, let index = apiKeys.firstIndex(where: { $0.keyId == apiKey.keyId }) else {
            return
        }
        apiKeys.remove(at: index)
        self.apiKeys = apiKeys
        didDeleteAPIKey.send(apiKey)
    }
}

public extension APIKeyController {
    static func forPreview(apiKeys: [APIKey]? = nil) -> APIKeyController {
        let controller = APIKeyController(keychainServiceName: "AppStoreConnectKit-Preview", keychain: Keychain.forPreview())
        controller.apiKeys = apiKeys
        return controller
    }
}
