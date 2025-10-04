import Combine
@testable import ConnectAccounts
import ConnectTestSupport
import Security
import Testing

@MainActor @Suite("Add API key", .tags(.apiKeys))
struct AddAPIKeyTests {
    let apiKey = try! APIKey(name: "Apple", keyId: "P9M252746H", issuerId: "82067982-6b3b-4a48-be4f-5b10b373c5f2", privateKey: """
    -----BEGIN PRIVATE KEY-----
    MIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQgevZzL1gdAFr88hb2
    OF/2NxApJCzGCEDdfSp6VQO30hyhRANCAAQRWz+jn65BtOMvdyHKcvjBeBSDZH2r
    1RTwjmYSi9R/zpBnuQ4EiMnCqfMPWiZqB4QdbAd0E7oH50VpuZ1P087G
    -----END PRIVATE KEY-----
    """)

    @Test("Add API Key")
    func addAPIKey() async throws {
        // Arrange
        let mockKeychain = MockKeychain()
        let controller = APIKeyController(service: "AppStoreConnectKit", keychain: mockKeychain)
        #expect(controller.apiKeys == nil)
        #expect(controller.selectedAPIKey == nil)
        #expect(mockKeychain.genericPasswordsInKeychain.isEmpty)
        var addedAPIKeys = [APIKey]()
        var cancellables = Set<AnyCancellable>()
        controller.didAddAPIKey.sink { addedAPIKeys.append($0) }.store(in: &cancellables)
        // Act
        try controller.addAPIKey(apiKey)
        // Assert
        #expect(controller.apiKeys == [apiKey])
        #expect(controller.selectedAPIKey == apiKey)
        #expect(try mockKeychain.genericPasswordsInKeychain == [apiKey.getGenericPassword()])
        #expect(addedAPIKeys == [apiKey])
    }

    @Test("Add API Key - Duplicate error")
    func addAPIKey_Duplicate() {
        // Arrange
        let mockKeychain = MockKeychain()
        mockKeychain.returnStatusForAdd = errSecDuplicateItem
        let controller = APIKeyController(service: "AppStoreConnectKit", keychain: mockKeychain)
        var addedAPIKeys = [APIKey]()
        var cancellables = Set<AnyCancellable>()
        controller.didAddAPIKey.sink { addedAPIKeys.append($0) }.store(in: &cancellables)
        // Act
        #expect(throws: APIKeyError.duplicateAPIKey) {
            try controller.addAPIKey(apiKey)
        }
        // Assert
        #expect(controller.apiKeys == nil)
        #expect(controller.selectedAPIKey == nil)
        #expect(addedAPIKeys == [])
    }

    @Test("Add API Key - Unknown error")
    func addAPIKey_Unknown() {
        // Arrange
        let status = errSecParam
        let mockKeychain = MockKeychain()
        mockKeychain.returnStatusForAdd = status
        let controller = APIKeyController(service: "AppStoreConnectKit", keychain: mockKeychain)
        var addedAPIKeys = [APIKey]()
        var cancellables = Set<AnyCancellable>()
        controller.didAddAPIKey.sink { addedAPIKeys.append($0) }.store(in: &cancellables)
        // Act
        #expect(throws: APIKeyError.failedAddingAPIKey(status)) {
            try controller.addAPIKey(apiKey)
        }
        // Assert
        #expect(controller.apiKeys == nil)
        #expect(controller.selectedAPIKey == nil)
        #expect(addedAPIKeys == [])
    }
}
