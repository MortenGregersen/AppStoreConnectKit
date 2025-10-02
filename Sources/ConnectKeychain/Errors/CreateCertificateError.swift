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
    /// Could not create signing request.
    case errorCreatingSigningRequest

    public var description: String {
        switch self {
        case .errorCreatingPublicKey: "Could not create public key"
        case .errorCreatingSigningRequest: "Could not create signing request"
        }
    }
}
