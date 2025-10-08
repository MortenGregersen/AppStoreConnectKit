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

@Suite("Certificate creator", .tags(.certificates))
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
        let certificateCreator = await CertificateCreator(keychain: mockKeychain, connectClient: .init(bagbutikService: mockBagbutikService), buildCSRAndReturnString: { _, _, _ in
            "valid csr"
        })
        // Act
        let certificate = try await certificateCreator.createCertificate(type: .development, keyNamePrefix: "AppStoreConnectKit")
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
        let certificateCreator = await CertificateCreator(keychain: mockKeychain, connectClient: .init(bagbutikService: mockBagbutikService))
        // Act
        let error = await #expect(throws: NSError.self) {
            try await certificateCreator.createCertificate(type: .development, keyNamePrefix: "AppStoreConnectKit")
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
        let certificateCreator = await CertificateCreator(keychain: mockKeychain, connectClient: .init(bagbutikService: mockBagbutikService))
        // Act/assert
        await #expect(throws: CreateCertificateError.errorCreatingPublicKey) {
            try await certificateCreator.createCertificate(type: .development, keyNamePrefix: "AppStoreConnectKit")
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
        let certificateCreator = await CertificateCreator(keychain: mockKeychain, connectClient: .init(bagbutikService: mockBagbutikService))
        // Act/assert
        await #expect(throws: CreateCertificateError.errorGettingPublicKeyData) {
            try await certificateCreator.createCertificate(type: .development, keyNamePrefix: "AppStoreConnectKit")
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
        let certificateCreator = await CertificateCreator(keychain: mockKeychain, connectClient: .init(bagbutikService: mockBagbutikService)) { _, _, _ in
            nil
        }
        // Act/assert
        await #expect(throws: CreateCertificateError.errorCreatingSigningRequest) {
            try await certificateCreator.createCertificate(type: .development, keyNamePrefix: "AppStoreConnectKit")
        }
    }
}

extension Tag {
    @Tag static var certificates: Self
}
