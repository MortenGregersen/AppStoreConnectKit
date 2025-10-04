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

    public convenience init(connectClient: AppStoreConnectClient) {
        self.init(keychain: Keychain(), connectClient: connectClient)
    }

    init(keychain: KeychainProtocol, connectClient: AppStoreConnectClient) {
        self.keychain = keychain
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
        let csr = CertificateSigningRequest()
        guard let csrString = csr.buildCSRAndReturnString(publicKey.data as Data, privateKey: privateKey, publicKey: publicKey.key) else {
            throw CreateCertificateError.errorCreatingSigningRequest
        }
        let requestBody = CertificateCreateRequest(data: .init(attributes: .init(certificateType: type, csrContent: csrString)))
        let certificateResponse = try await connectClient.request(.createCertificateV1(requestBody: requestBody))
        return certificateResponse.data
    }
}
