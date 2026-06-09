@testable import ConnectAccounts
import ConnectKeychain
import Foundation
import Testing

@Suite("API key value", .tags(.apiKeys))
struct APIKeyTests {
    private func jsonData(_ values: [String: Any]) throws -> Data {
        try JSONSerialization.data(withJSONObject: values)
    }

    @Test("ID is key ID")
    func idIsKeyId() throws {
        let apiKey = try APIKeyFixture.makeAPIKey(keyId: "ABC123DEF4")

        #expect(apiKey.id == "ABC123DEF4")
    }

    @Test("Encode writes stored credentials only")
    func encodeWritesStoredCredentialsOnly() throws {
        let apiKey = try APIKeyFixture.makeAPIKey()
        let data = try JSONEncoder().encode(apiKey)
        let json = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

        #expect(json["name"] as? String == apiKey.name)
        #expect(json["keyId"] as? String == apiKey.keyId)
        #expect(json["issuerId"] as? String == apiKey.issuerId)
        #expect(json["privateKey"] as? String == apiKey.privateKey)
        #expect(json["jwt"] == nil)
    }

    @Test("Decode regenerates JWT")
    func decodeRegeneratesJWT() throws {
        let data = try jsonData([
            "name": "Apple",
            "keyId": "P9M252746H",
            "issuerId": APIKeyFixture.issuerId,
            "privateKey": APIKeyFixture.privateKey
        ])

        let apiKey = try JSONDecoder().decode(APIKey.self, from: data)

        #expect(apiKey.name == "Apple")
        #expect(apiKey.keyId == "P9M252746H")
        #expect(apiKey.issuerId == APIKeyFixture.issuerId)
        #expect(apiKey.privateKey == APIKeyFixture.privateKey)
        #expect(apiKey.jwt.encodedSignature.isEmpty == false)
    }

    @Test("Decode missing issuer as app key")
    func decodeMissingIssuerAsAppKey() throws {
        let data = try jsonData([
            "name": "Apple",
            "keyId": "P9M252746H",
            "privateKey": APIKeyFixture.privateKey
        ])

        let apiKey = try JSONDecoder().decode(APIKey.self, from: data)

        #expect(apiKey.issuerId == nil)
        #expect(apiKey.jwt.encodedSignature.isEmpty == false)
    }

    @Test("Decode empty issuer as app key")
    func decodeEmptyIssuerAsAppKey() throws {
        let data = try jsonData([
            "name": "Apple",
            "keyId": "P9M252746H",
            "issuerId": "",
            "privateKey": APIKeyFixture.privateKey
        ])

        let apiKey = try JSONDecoder().decode(APIKey.self, from: data)

        #expect(apiKey.issuerId == nil)
        #expect(apiKey.jwt.encodedSignature.isEmpty == false)
    }

    @Test("Equality includes stored credentials")
    func equalityIncludesStoredCredentials() throws {
        let apiKey = try APIKeyFixture.makeAPIKey()
        let changedName = try APIKeyFixture.makeAPIKey(name: "Google")
        let changedKeyId = try APIKeyFixture.makeAPIKey(keyId: "H647252M9P")
        let changedIssuer = try APIKeyFixture.makeAPIKey(issuerId: "57246542-96fe-1a63-e053-0824d011072a")
        let changedPrivateKey = try APIKeyFixture.makeAPIKey(privateKey: APIKeyFixture.privateKey + "\n")
        let sameAPIKey = try APIKeyFixture.makeAPIKey()

        #expect(apiKey == sameAPIKey)
        #expect(apiKey != changedName)
        #expect(apiKey != changedKeyId)
        #expect(apiKey != changedIssuer)
        #expect(apiKey != changedPrivateKey)
    }

    @Test("Set keeps distinct stored credentials")
    func setKeepsDistinctStoredCredentials() throws {
        let apiKeys = try Set([
            APIKeyFixture.makeAPIKey(),
            APIKeyFixture.makeAPIKey(),
            APIKeyFixture.makeAPIKey(name: "Google"),
            APIKeyFixture.makeAPIKey(keyId: "H647252M9P"),
            APIKeyFixture.makeAPIKey(issuerId: nil)
        ])

        #expect(apiKeys.count == 4)
    }

    @Test("Generic password round trips team key")
    func genericPasswordRoundTripsTeamKey() throws {
        let apiKey = try APIKeyFixture.makeAPIKey()
        let password = try apiKey.getGenericPassword()

        #expect(password.account == apiKey.keyId)
        #expect(password.label == apiKey.name)
        #expect(String(data: password.generic, encoding: .utf8) == apiKey.issuerId)
        #expect(String(data: password.value, encoding: .utf8) == apiKey.privateKey)
        #expect(try APIKey(password: password) == apiKey)
    }

    @Test("Generic password round trips app key")
    func genericPasswordRoundTripsAppKey() throws {
        let apiKey = try APIKeyFixture.makeAPIKey(issuerId: nil)
        let password = try apiKey.getGenericPassword()

        #expect(password.generic.isEmpty)
        #expect(try APIKey(password: password) == apiKey)
    }

    @Test("Generic password rejects invalid text data")
    func genericPasswordRejectsInvalidTextData() {
        let password = GenericPassword(account: "P9M252746H",
                                       label: "Apple",
                                       generic: Data([0xFF]),
                                       value: Data(APIKeyFixture.privateKey.utf8))

        #expect(throws: APIKeyError.invalidAPIKeyFormat) {
            try APIKey(password: password)
        }
    }
}
