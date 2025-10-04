@testable import ConnectAccounts
import ConnectKeychain
import ConnectTestSupport
import Foundation
import Testing

@MainActor @Suite("List API keys", .tags(.apiKeys))
struct ListAPIKeysTests {
    let valid = try! APIKey(name: "Apple", keyId: "P9M252746H", issuerId: "82067982-6b3b-4a48-be4f-5b10b373c5f2", privateKey: """
    -----BEGIN PRIVATE KEY-----
    MIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQgevZzL1gdAFr88hb2
    OF/2NxApJCzGCEDdfSp6VQO30hyhRANCAAQRWz+jn65BtOMvdyHKcvjBeBSDZH2r
    1RTwjmYSi9R/zpBnuQ4EiMnCqfMPWiZqB4QdbAd0E7oH50VpuZ1P087G
    -----END PRIVATE KEY-----
    """)

    let invalidGeneric = GenericPassword(account: "H647252M9P", label: "Epic Games", generic: Data(), value: Data())
    let invalidValue = GenericPassword(account: "H647252M9P", label: "Epic Games", generic: Data("82067982-6b3b-4a48-be4f-5b10b373c5f2".utf8), value: Data())

    @Test("List API Keys")
    func listAPIKeys() async throws {
        // Arrange
        let mockKeychain = MockKeychain()
        mockKeychain.genericPasswordsInKeychain = try [valid.getGenericPassword()]
        let controller = APIKeyController(service: "AppStoreConnectKit", keychain: mockKeychain)
        // Act
        try await controller.loadAPIKeys()
        // Assert
        #expect(controller.apiKeys == [valid])
    }

    @Test("List API Keys - Invalid issuer")
    func listAPIKeys_InvalidIssuer() async throws {
        // Arrange
        let mockKeychain = MockKeychain()
        mockKeychain.genericPasswordsInKeychain = [invalidGeneric]
        let controller = APIKeyController(service: "AppStoreConnectKit", keychain: mockKeychain)
        // Act
        await #expect(throws: APIKeyError.invalidAPIKeyFormat) {
            try await controller.loadAPIKeys()
        }
        // Assert
        #expect(controller.apiKeys == nil)
    }

    @Test("List API Keys - Invalid private key")
    func listAPIKeys_InvalidPrivateKey() async throws {
        // Arrange
        let mockKeychain = MockKeychain()
        mockKeychain.genericPasswordsInKeychain = [invalidValue]
        let controller = APIKeyController(service: "AppStoreConnectKit", keychain: mockKeychain)
        // Act
        await #expect(throws: APIKeyError.invalidAPIKeyFormat) {
            try await controller.loadAPIKeys()
        }
        // Assert
        #expect(controller.apiKeys == nil)
    }
}

extension Tag {
    @Tag static var apiKeys: Self
}
