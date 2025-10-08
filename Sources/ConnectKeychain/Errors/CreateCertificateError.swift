//
//  CreateCertificateError.swift
//  ConnectKeychain
//
//  Created by Morten Bjerg Gregersen on 02/10/2025.
//

import Foundation

/// Error happening when creating certificates.
public enum CreateCertificateError: LocalizedError, Equatable {
    /// Could not create public key.
    case errorCreatingPublicKey
    /// Could not get public key data (external representation).
    case errorGettingPublicKeyData
    /// Could not create signing request.
    case errorCreatingSigningRequest

    public var description: String {
        switch self {
        case .errorCreatingPublicKey: "Could not create public key"
        case .errorGettingPublicKeyData: "Could not get public key data"
        case .errorCreatingSigningRequest: "Could not create signing request"
        }
    }
}

