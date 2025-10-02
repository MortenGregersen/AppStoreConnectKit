//
//  AddCertificateToKeychainError.swift
//  ConnectKeychain
//
//  Created by Morten Bjerg Gregersen on 02/10/2025.
//

import Foundation

/// Error happening when adding certificates to Keychain.
public enum AddCertificateToKeychainError: LocalizedError, Equatable {
    /// The certificate fetched from App Store Connect is incomplete
    case invalidOnlineCertificateData
    /// An error occurred when adding certificate to Keychain. Lookup the status on <https://osstatus.com>.
    case errorAddingCertificateToKeychain(status: OSStatus)

    public var description: String {
        switch self {
        case .invalidOnlineCertificateData:
            return "The certificate fetched from App Store Connect is incomplete"
        case .errorAddingCertificateToKeychain(let status):
            return "Unknown error occurred when adding certificate to Keychain (OSStatus: \(status))"
        }
    }
}
