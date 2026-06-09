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
        let controller = APIKeyController(keychainServiceName: "AppStoreConnectKit", keychain: mockKeychain)
        #expect(controller.apiKeys == nil)
        #expect(mockKeychain.genericPasswordsInKeychain.isEmpty)
        // Act
        try controller.addAPIKey(apiKey)
        // Assert
        #expect(controller.apiKeys == [apiKey])
        #expect(try mockKeychain.genericPasswordsInKeychain == [apiKey.getGenericPassword()])
    }

    @Test("Add API Key - Duplicate error")
    func addAPIKey_Duplicate() throws {
        // Arrange
        let mockKeychain = MockKeychain()
        let controller = APIKeyController(keychainServiceName: "AppStoreConnectKit", keychain: mockKeychain)
        try controller.addAPIKey(apiKey)
        #expect(controller.apiKeys == [apiKey])
        // Act
        #expect(throws: APIKeyError.duplicateAPIKey) {
            try controller.addAPIKey(apiKey)
        }
        // Assert
        #expect(controller.apiKeys == [apiKey])
    }

    @Test("Add API Key - Inserts sorted")
    func addAPIKey_InsertsSorted() throws {
        // Arrange
        let banana = try APIKeyFixture.makeAPIKey(name: "Banana", keyId: "BANANA1234")
        let apple = try APIKeyFixture.makeAPIKey(name: "Apple", keyId: "APPLE1234")
        let mockKeychain = MockKeychain()
        let controller = APIKeyController(keychainServiceName: "AppStoreConnectKit", keychain: mockKeychain)
        try controller.addAPIKey(banana)
        // Act
        try controller.addAPIKey(apple)
        // Assert
        #expect(controller.apiKeys == [apple, banana])
    }

    @Test("Add API Key - Loads before adding")
    func addAPIKey_LoadsBeforeAdding() throws {
        // Arrange
        let apple = try APIKeyFixture.makeAPIKey(name: "Apple", keyId: "APPLE1234")
        let banana = try APIKeyFixture.makeAPIKey(name: "Banana", keyId: "BANANA1234")
        let mockKeychain = MockKeychain()
        mockKeychain.genericPasswordsInKeychain = try [banana.getGenericPassword()]
        let controller = APIKeyController(keychainServiceName: "AppStoreConnectKit", keychain: mockKeychain)
        #expect(controller.apiKeys == nil)
        // Act
        try controller.addAPIKey(apple)
        // Assert
        #expect(controller.apiKeys == [apple, banana])
        #expect(mockKeychain.genericPasswordsInKeychain.count == 2)
    }

    @Test("Add API Key - Unknown error")
    func addAPIKey_Unknown() {
        // Arrange
        let status = errSecParam
        let mockKeychain = MockKeychain()
        mockKeychain.returnStatusForAdd = status
        let controller = APIKeyController(keychainServiceName: "AppStoreConnectKit", keychain: mockKeychain)
        #expect(controller.apiKeys == nil)
        // Act
        #expect(throws: APIKeyError.failedAddingAPIKey(status)) {
            try controller.addAPIKey(apiKey)
        }
        // Assert
        #expect(controller.apiKeys == [])
    }
}
