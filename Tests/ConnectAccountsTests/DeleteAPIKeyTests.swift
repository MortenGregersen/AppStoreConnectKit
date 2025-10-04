@testable import ConnectAccounts
import ConnectKeychain
import ConnectTestSupport
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
        let controller = APIKeyController(service: "AppStoreConnectKit", keychain: mockKeychain)
        try await controller.loadAPIKeys()
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
        let controller = APIKeyController(service: "AppStoreConnectKit", keychain: mockKeychain)
        try await controller.loadAPIKeys()
        #expect(controller.apiKeys == [apiKey])
        // Act
        #expect(throws: KeychainError.failedDeletingPassword) {
            try controller.deleteAPIKey(apiKey)
        }
        // Assert
        #expect(controller.apiKeys == [apiKey])
    }
}
