//
//  CertificateManager.swift
//  AppStoreConnectKit
//
//  Created by Morten Bjerg Gregersen on 03/10/2025.
//

import Bagbutik_Models
import Bagbutik_Provisioning
import CertificateSigningRequest
import ConnectClient
import ConnectKeychain
import Foundation

/// Error happening when creating certificates.
public enum CreateCertificateError: LocalizedError, Equatable {
    /// Could not create signing request.
    case errorCreatingSigningRequest

    public var description: String {
        switch self {
        case .errorCreatingSigningRequest:
            "Could not create signing request"
        }
    }

    public var errorDescription: String? { description }
}

/// Error happening when adding certificates to Keychain.
public enum AddCertificateToKeychainError: LocalizedError, Equatable {
    /// The certificate fetched from App Store Connect is incomplete.
    case invalidOnlineCertificateData

    public var description: String {
        switch self {
        case .invalidOnlineCertificateData:
            "The certificate fetched from App Store Connect is incomplete"
        }
    }

    public var errorDescription: String? { description }
}

public class CertificateManager {
    private let keychain: KeychainProtocol
    private let connectClient: AppStoreConnectClient
    private let buildCSRAndReturnString: (Data, SecKey, SecKey?) -> String?

    public convenience init(keychain: KeychainProtocol, connectClient: AppStoreConnectClient) {
        self.init(keychain: keychain, connectClient: connectClient, buildCSRAndReturnString: {
            let signingRequest = CertificateSigningRequest()
            return signingRequest.buildCSRAndReturnString($0, privateKey: $1, publicKey: $2)
        })
    }

    init(keychain: KeychainProtocol, connectClient: AppStoreConnectClient, buildCSRAndReturnString: @escaping (Data, SecKey, SecKey?) -> String?) {
        self.keychain = keychain
        self.buildCSRAndReturnString = buildCSRAndReturnString
        self.connectClient = connectClient
    }

    /**
     Create a new certificate of a specific type.

     - Parameters:
       - type: The type of certificate to create.
     - Returns: The newly created `Certificate`.
     */
    @discardableResult public nonisolated(nonsending)
    func createCertificate(type: CertificateType, keyNamePrefix: String) async throws -> Certificate {
        let label = "\(keyNamePrefix) \(Date().timeIntervalSince1970)"
        let privateKey = try keychain.createPrivateKey(labeled: label)
        let publicKey = try keychain.createPublicKey(from: privateKey)
        guard let csrString = buildCSRAndReturnString(publicKey.data as Data, privateKey, publicKey.key) else {
            throw CreateCertificateError.errorCreatingSigningRequest
        }
        let requestBody = CertificateCreateRequest(data: .init(attributes: .init(certificateType: type, csrContent: csrString)))
        let certificateResponse = try await connectClient.request(.createCertificateV1(requestBody: requestBody))
        return certificateResponse.data
    }

    /**
     Add a certificate fetched from App Store Connect to the Keychain.

     - Parameters:
       - certificate: The `Certificate` to add to the Keychain.
       - fallbackName: The name to use if the certificate does not have a name.
     */
    public func addCertificateToKeychain(certificate: Certificate, fallbackName: String = "Certificate \(Date())") throws {
        let name = certificate.attributes?.name ?? fallbackName
        guard
            let certificateContent = certificate.attributes?.certificateContent,
            let certificateData = Data(base64Encoded: certificateContent)
        else {
            throw AddCertificateToKeychainError.invalidOnlineCertificateData
        }
        try addCertificateToKeychain(certificateData: certificateData, name: name)
    }

    /**
     Add a certificate fetched from App Store Connect to the Keychain.

     - Parameters:
       - certificateData: The raw certificate data to add to the Keychain..
       - name: The name to use for the certificate in the Keychain.
     */
    public func addCertificateToKeychain(certificateData: Data, name: String) throws {
        guard let secCertificate = SecCertificateCreateWithData(nil, certificateData as CFData) else {
            throw AddCertificateToKeychainError.invalidOnlineCertificateData
        }
        try keychain.addCertificate(certificate: secCertificate, named: name)
    }
}

extension CertificateSigningRequest {
    static func create() -> CertificateSigningRequest {
        CertificateSigningRequest()
    }
}
