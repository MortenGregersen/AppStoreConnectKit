//
//  APIKeyCredentials.swift
//  ConnectAccountsUI
//
//  Created by Morten Bjerg Gregersen on 27/10/2025.
//

/// Struct representing API key credentials.
public struct APIKeyCredentials: Sendable {
    public let keyId: String
    public let issuerId: String?
    public let privateKey: String

    /**
     Initializes a new instance of `APIKeyCredentials`.
     - Parameters:
       - keyId: The key ID.
       - issuerId: The issuer ID (optional).
       - privateKey: The private key.
     */
    public init(keyId: String, issuerId: String?, privateKey: String) {
        self.keyId = keyId
        self.issuerId = issuerId
        self.privateKey = privateKey
    }
}
