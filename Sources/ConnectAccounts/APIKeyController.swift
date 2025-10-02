import Combine
import ConnectCore
import ConnectKeychain
import Foundation

@Observable
public class APIKeyController {
    public private(set) var apiKeys: FetchingState<[APIKey]>?
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
    private var selectedAPIKeyId: String? {
        get { UserDefaults.standard.string(forKey: "selected-api-key-id") }
        set { UserDefaults.standard.set(newValue, forKey: "selected-api-key-id") }
    }

    public init(service: String) {
        precondition(!service.isEmpty, "Service must not be empty")
        self.service = service
        loadAPIKeys()
    }

    public func loadAPIKeys() {
        apiKeys = .fetching
        do {
            let apiKeys = try Keychain().listGenericPasswords(forService: service)
                .map { password -> APIKey in
                    guard let apiKey = try? APIKey(password: password)
                    else { throw APIKeyError.invalidAPIKeyFormat }
                    return apiKey
                }
                .sorted { $0.name < $1.name }
            self.apiKeys = .fetched(apiKeys)
            if let apiKey = apiKeys.first(where: { $0.keyId == selectedAPIKeyId }) ?? apiKeys.first {
                selectedAPIKey = apiKey
            }
        } catch {
            apiKeys = .error(mapErrorToConnectError(error: error))
        }
    }

    public func addAPIKey(_ apiKey: APIKey) throws {
        do {
            try Keychain().addGenericPassword(forService: service, password: apiKey.getGenericPassword())
        } catch KeychainError.duplicatePassword {
            throw APIKeyError.duplicateAPIKey
        } catch KeychainError.failedAddingPassword(let status) {
            throw APIKeyError.failedAddingAPIKey(status)
        }
        guard case .fetched(var apiKeys) = apiKeys else { return }
        if apiKeys.isEmpty {
            selectedAPIKey = apiKey
        }
        apiKeys.append(apiKey)
        self.apiKeys = .fetched(apiKeys)
        didAddAPIKey.send(apiKey)
    }

    public func deleteAPIKey(_ apiKey: APIKey) throws {
        try Keychain().deleteGenericPassword(forService: service, password: apiKey.getGenericPassword())
        guard case .fetched(var apiKeys) = apiKeys,
              let index = apiKeys.firstIndex(where: { $0.keyId == apiKey.keyId }) else {
            return
        }
        apiKeys.remove(at: index)
        self.apiKeys = .fetched(apiKeys)
        didDeleteAPIKey.send(apiKey)
    }
}

public extension APIKeyController {
    static func forPreview(apiKeys: FetchingState<[APIKey]>? = nil) -> APIKeyController {
        let controller = APIKeyController(service: "AppStoreConnectKit-Preview")
        controller.apiKeys = apiKeys
        return controller
    }
}
