//
//  CertificateCreator.swift
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

public class CertificateCreator {
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
    @discardableResult
    public func createCertificate(type: CertificateType, keyNamePrefix: String) async throws -> Certificate {
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
}

extension CertificateSigningRequest {
    static func create() -> CertificateSigningRequest {
        CertificateSigningRequest()
    }
}
