//
//  CreateCertificateTests.swift
//  AppStoreConnectKit
//
//  Created by Morten Bjerg Gregersen on 03/10/2025.
//

import Bagbutik_Models
import Bagbutik_Provisioning
import CertificateSigningRequest
import ConnectKeychain
@testable import ConnectProvisioning
import ConnectTestSupport
import Foundation
import Testing

@Suite("Certificate manager", .tags(.certificates))
struct CreateCertificateTests {
    @Test("Create certificate")
    func createCertificate() async throws {
        // Arrange
        let response = CertificateResponse(
            data: .init(id: "some-id", links: .init(self: "")),
            links: .init(self: "")
        )
        let mockBagbutikService = MockBagbutikService()
        mockBagbutikService.setResponse(response, for: Endpoint(path: "/v1/certificates", method: .post))
        let mockKeychain = MockKeychain()
        mockKeychain.publicKeyDataToReturn = "some public key".data(using: .utf8)
        let certificateManager = CertificateManager(keychain: mockKeychain, connectClient: .init(bagbutikService: mockBagbutikService), buildCSRAndReturnString: { _, _, _ in
            "valid csr"
        })
        // Act
        let certificate = try await certificateManager.createCertificate(type: .development, keyNamePrefix: "AppStoreConnectKit")
        // Assert
        #expect(certificate.id == response.data.id)
    }

    @Test("Create certificate - Unable to create private key")
    func createCertificate_UnableToCreatePrivateKey() async {
        // Arrange
        let response = CertificateResponse(
            data: .init(id: "some-id", links: .init(self: "")),
            links: .init(self: "")
        )
        let mockBagbutikService = MockBagbutikService()
        mockBagbutikService.setResponse(response, for: Endpoint(path: "/v1/certificates", method: .post))
        let mockKeychain = MockKeychain()
        mockKeychain.createRandomKeyShouldSucceed = false
        let certificateManager = CertificateManager(keychain: mockKeychain, connectClient: .init(bagbutikService: mockBagbutikService))
        // Act
        let error = await #expect(throws: NSError.self) {
            try await certificateManager.createCertificate(type: .development, keyNamePrefix: "AppStoreConnectKit")
        }
        #expect(error?.domain == "SecKeyCreateRandomKey")
    }

    @Test("Create certificate - Unable to create public key")
    func createCertificate_UnableToCreatePublicKey() async {
        // Arrange
        let response = CertificateResponse(
            data: .init(id: "some-id", links: .init(self: "")),
            links: .init(self: "")
        )
        let mockBagbutikService = MockBagbutikService()
        mockBagbutikService.setResponse(response, for: Endpoint(path: "/v1/certificates", method: .post))
        let mockKeychain = MockKeychain()
        mockKeychain.copyPublicKeyShouldSucceed = false
        let certificateManager = CertificateManager(keychain: mockKeychain, connectClient: .init(bagbutikService: mockBagbutikService))
        // Act/assert
        await #expect(throws: KeychainError.errorCreatingPublicKey) {
            try await certificateManager.createCertificate(type: .development, keyNamePrefix: "AppStoreConnectKit")
        }
    }

    @Test("Create certificate - Unable to get public key data")
    func createCertificate_UnableToGetPublicKeyData() async {
        // Arrange
        let response = CertificateResponse(
            data: .init(id: "some-id", links: .init(self: "")),
            links: .init(self: "")
        )
        let mockBagbutikService = MockBagbutikService()
        mockBagbutikService.setResponse(response, for: Endpoint(path: "/v1/certificates", method: .post))
        let mockKeychain = MockKeychain()
        mockKeychain.copyPublicKeyDataShouldSucceed = false
        let certificateManager = CertificateManager(keychain: mockKeychain, connectClient: .init(bagbutikService: mockBagbutikService))
        // Act/assert
        await #expect(throws: KeychainError.errorGettingPublicKeyData) {
            try await certificateManager.createCertificate(type: .development, keyNamePrefix: "AppStoreConnectKit")
        }
    }

    @Test("Create certificate - Unable to create signing request")
    func createCertificate_InvalidPublicKeyData() async throws {
        // Arrange
        let response = CertificateResponse(
            data: .init(id: "some-id", links: .init(self: "")),
            links: .init(self: "")
        )
        let mockBagbutikService = MockBagbutikService()
        mockBagbutikService.setResponse(response, for: Endpoint(path: "/v1/certificates", method: .post))
        let mockKeychain = MockKeychain()
        mockKeychain.publicKeyDataToReturn = "some invalid public key".data(using: .utf8)
        let certificateManager = CertificateManager(keychain: mockKeychain, connectClient: .init(bagbutikService: mockBagbutikService)) { _, _, _ in
            nil
        }
        // Act/assert
        await #expect(throws: CreateCertificateError.errorCreatingSigningRequest) {
            try await certificateManager.createCertificate(type: .development, keyNamePrefix: "AppStoreConnectKit")
        }
    }

    @Test("Add certificate to keychain")
    func addCertificateToKeychain() async throws {
        let pemCertificate = """
        -----BEGIN CERTIFICATE-----
        MIIEGzCCAwOgAwIBAgIUfqvmN2iVUoYPIu0Tb0olyHvWj4kwDQYJKoZIhvcNAQEL
        BQAwgZwxCzAJBgNVBAYTAkRLMRQwEgYDVQQIDAtNaWR0anlsbGFuZDESMBAGA1UE
        BwwJU2lsa2Vib3JnMRowGAYDVQQKDBFBdHRlcmRhZyBBcHBzIEFwUzEfMB0GA1UE
        AwwWTW9ydGVuIEJqZXJnIEdyZWdlcnNlbjEmMCQGCSqGSIb3DQEJARYXbW9ydGVu
        QGF0dGVyZGFnYXBwcy5jb20wHhcNMjUxMDA4MjAwMzEyWhcNMjYxMDA4MjAwMzEy
        WjCBnDELMAkGA1UEBhMCREsxFDASBgNVBAgMC01pZHRqeWxsYW5kMRIwEAYDVQQH
        DAlTaWxrZWJvcmcxGjAYBgNVBAoMEUF0dGVyZGFnIEFwcHMgQXBTMR8wHQYDVQQD
        DBZNb3J0ZW4gQmplcmcgR3JlZ2Vyc2VuMSYwJAYJKoZIhvcNAQkBFhdtb3J0ZW5A
        YXR0ZXJkYWdhcHBzLmNvbTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEB
        AJ9/8rzUUIgaQHdZdAz0Pqf1Dqr+fHXyLWb+0SHWwX8LuN4MLSgVuxIyUSfT3xMi
        jyYAAfKxdy0+IaWBxU2yE/NREPjImNmyBzdbikJAEX8/yIIzxN55tu7IMMmu31OY
        tUenQeSvUjMk5F/SU9UkNAmH/eXzm/n4k1C2iVoF6GbLLaDn1nfowS309qfZnvUG
        S5dJNxuNxUqzUiKFbzxj9/dLUJNH8Lp59J8J2Z+bPFxfxeH3u6uOepCXOJD5Xm8G
        W3I3FE5aptQAeQ18/mBYY/7gz+fXUl6SejTMCMoWTZkPazm7GrlW1bLIcjxAd4aW
        pr08UQwee33JoodnPAUY8M8CAwEAAaNTMFEwHQYDVR0OBBYEFIS1y8xvyOsHJCej
        ZcTPwr7eq2wpMB8GA1UdIwQYMBaAFIS1y8xvyOsHJCejZcTPwr7eq2wpMA8GA1Ud
        EwEB/wQFMAMBAf8wDQYJKoZIhvcNAQELBQADggEBAHWvwDN323GuvE3I8pMS5m05
        VcxVZs200uV74TSIHP0T3cSOwnsF1oTdBm81dRNJk72oB9TagZDpyEgMYNXNEKEQ
        KoiDE4/sgtmclnJ0wNZDMf9IVDCbfFhIGdLRTfvF2/2/pG6WdDmI0oYiM65ngTXB
        P4XCnl3WhC6L9qzokPQKwoPdMLuzGMK5g+OG1x3i3kZCBd4Lr/wPttVHCBrijiSp
        UoJsg8O4clcjB0vJhg2PMj0B21H9VRJtlj8op33o9qllEXxOdDOKI6Jun+WhX68i
        SKZ2l2WxuG9QNzht68nqSko6SKLEcSluJ5GODnIXYffW9i+gpQaxKxih8B0EO88=
        -----END CERTIFICATE-----
        """
        let base64DER = pemCertificate
            .replacingOccurrences(of: "-----BEGIN CERTIFICATE-----", with: "")
            .replacingOccurrences(of: "-----END CERTIFICATE-----", with: "")
            .replacingOccurrences(of: "\r", with: "")
            .replacingOccurrences(of: "\n", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let derData = try #require(Data(base64Encoded: base64DER), "Inline PEM is not valid base64 DER. Paste a valid certificate.")
        let certificate = Certificate(
            id: "some-id",
            attributes: .init(
                certificateContent: derData.base64EncodedString(),
                certificateType: .development,
                name: "My Certificate"
            )
        )
        let mockKeychain = MockKeychain()
        let certificateManager = CertificateManager(keychain: mockKeychain, connectClient: .init(bagbutikService: MockBagbutikService()))
        #expect(mockKeychain.serialNumbersForCertificatesInKeychain.isEmpty)
        // Act
        try certificateManager.addCertificateToKeychain(certificate: certificate)
        // Assert
        #expect(mockKeychain.serialNumbersForCertificatesInKeychain == ["7eabe637689552860f22ed136f4a25c87bd68f89"])
    }

    @Test("Add certificate to keychain - missing content")
    func addCertificateToKeychain_MissingContent() async throws {
        // Arrange
        let certificate = Certificate(
            id: "some-id",
            attributes: .init(
                certificateContent: nil,
                certificateType: .development,
                name: "My Certificate"
            )
        )
        let mockKeychain = MockKeychain()
        let certificateManager = CertificateManager(keychain: mockKeychain, connectClient: .init(bagbutikService: MockBagbutikService()))
        // Act/assert
        #expect(throws: AddCertificateToKeychainError.invalidOnlineCertificateData) {
            try certificateManager.addCertificateToKeychain(certificate: certificate)
        }
    }

    @Test("Add certificate to keychain - invalid content")
    func addCertificateToKeychain_InvalidContent() async throws {
        // Arrange
        let certificateData = "some invalid certificate data".data(using: .utf8)!
        let certificate = Certificate(
            id: "some-id",
            attributes: .init(
                certificateContent: certificateData.base64EncodedString(),
                certificateType: .development,
                name: "My Certificate"
            )
        )
        let mockKeychain = MockKeychain()
        let certificateManager = CertificateManager(keychain: mockKeychain, connectClient: .init(bagbutikService: MockBagbutikService()))
        // Act/assert
        #expect(throws: AddCertificateToKeychainError.invalidOnlineCertificateData) {
            try certificateManager.addCertificateToKeychain(certificate: certificate)
        }
    }
}

extension Tag {
    @Tag static var certificates: Self
}
