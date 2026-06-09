@testable import ConnectAccounts
import ConnectKeychain
import ConnectTestSupport
import Foundation
import Security
import Testing

@MainActor @Suite("Delete API key", .tags(.apiKeys))
struct DeleteAPIKeyTests {
    let apiKey = try! APIKey(name: "Apple", keyId: "P9M252746H", issuerId: "82067982-6b3b-4a48-be4f-5b10b373c5f2", privateKey: """
    -----BEGIN PRIVATE KEY-----
    MIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQgevZzL1gdAFr88hb2
    OF/2NxApJCzGCEDdfSp6VQO30hyhRANCAAQRWz+jn65BtOMvdyHKcvjBeBSDZH2r
    1RTwjmYSi9R/zpBnuQ4EiMnCqfMPWiZqB4QdbAd0E7oH50VpuZ1P087G
    -----END PRIVATE KEY-----
    """)

    @Test("Delete API Key")
    func deleteAPIKey() async throws {
        // Arrange
        let mockKeychain = MockKeychain()
        mockKeychain.returnStatusForDelete = errSecSuccess
        mockKeychain.genericPasswordsInKeychain = try [apiKey.getGenericPassword()]
        let controller = APIKeyController(keychainServiceName: "AppStoreConnectKit", keychain: mockKeychain)
        try controller.loadAPIKeys()
        #expect(controller.apiKeys == [apiKey])
        // Act
        try controller.deleteAPIKey(apiKey)
        // Assert
        #expect((controller.apiKeys ?? []).isEmpty)
    }

    @Test("Delete API Key - Error deleting")
    func deleteAPIKey_Error() async throws {
        // Arrange
        let mockKeychain = MockKeychain()
        mockKeychain.returnStatusForDelete = errSecDatabaseLocked
        mockKeychain.genericPasswordsInKeychain = try [apiKey.getGenericPassword()]
        let controller = APIKeyController(keychainServiceName: "AppStoreConnectKit", keychain: mockKeychain)
        try controller.loadAPIKeys()
        #expect(controller.apiKeys == [apiKey])
        // Act
        #expect(throws: KeychainError.failedDeletingPassword) {
            try controller.deleteAPIKey(apiKey)
        }
        // Assert
        #expect(controller.apiKeys == [apiKey])
    }

    @Test("Delete API Key - Loads before deleting")
    func deleteAPIKey_LoadsBeforeDeleting() throws {
        // Arrange
        let apple = try APIKeyFixture.makeAPIKey(name: "Apple", keyId: "APPLE1234")
        let banana = try APIKeyFixture.makeAPIKey(name: "Banana", keyId: "BANANA1234")
        let mockKeychain = MockKeychain()
        mockKeychain.genericPasswordsInKeychain = try [apple.getGenericPassword(), banana.getGenericPassword()]
        let controller = APIKeyController(keychainServiceName: "AppStoreConnectKit", keychain: mockKeychain)
        #expect(controller.apiKeys == nil)
        // Act
        try controller.deleteAPIKey(banana)
        // Assert
        #expect(controller.apiKeys == [apple])
        #expect(try mockKeychain.genericPasswordsInKeychain == [apple.getGenericPassword()])
    }

    @Test("Delete API Key - Missing loaded key throws and leaves state unchanged")
    func deleteAPIKey_MissingLoadedKeyThrowsAndLeavesStateUnchanged() throws {
        // Arrange
        let apple = try APIKeyFixture.makeAPIKey(name: "Apple", keyId: "APPLE1234")
        let banana = try APIKeyFixture.makeAPIKey(name: "Banana", keyId: "BANANA1234")
        let mockKeychain = MockKeychain()
        mockKeychain.genericPasswordsInKeychain = try [apple.getGenericPassword()]
        let controller = APIKeyController(keychainServiceName: "AppStoreConnectKit", keychain: mockKeychain)
        try controller.loadAPIKeys()
        // Act
        #expect(throws: KeychainError.failedDeletingPassword) {
            try controller.deleteAPIKey(banana)
        }
        // Assert
        #expect(controller.apiKeys == [apple])
        #expect(try mockKeychain.genericPasswordsInKeychain == [apple.getGenericPassword()])
    }

    @Test("Preview controller uses supplied keys")
    func previewControllerUsesSuppliedKeys() throws {
        let apiKeys = try [APIKeyFixture.makeAPIKey()]
        let controller = APIKeyController.forPreview(apiKeys: apiKeys)

        #expect(controller.apiKeys == apiKeys)
    }
}
