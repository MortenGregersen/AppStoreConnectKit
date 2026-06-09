@testable import ConnectAccounts

enum APIKeyFixture {
    static let privateKey = """
    -----BEGIN PRIVATE KEY-----
    MIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQgevZzL1gdAFr88hb2
    OF/2NxApJCzGCEDdfSp6VQO30hyhRANCAAQRWz+jn65BtOMvdyHKcvjBeBSDZH2r
    1RTwjmYSi9R/zpBnuQ4EiMnCqfMPWiZqB4QdbAd0E7oH50VpuZ1P087G
    -----END PRIVATE KEY-----
    """

    static let issuerId = "82067982-6b3b-4a48-be4f-5b10b373c5f2"

    static func makeAPIKey(name: String = "Apple",
                           keyId: String = "P9M252746H",
                           issuerId: String? = Self.issuerId,
                           privateKey: String = Self.privateKey) throws -> APIKey
    {
        try APIKey(name: name, keyId: keyId, issuerId: issuerId, privateKey: privateKey)
    }
}
