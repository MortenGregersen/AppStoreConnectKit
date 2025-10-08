//
//  KeychainError.swift
//  ConnectKeychain
//
//  Created by Morten Bjerg Gregersen on 02/10/2025.
//

import ConnectCore
import Foundation

public enum KeychainError: LocalizedError, Equatable {
    /// An error occurred when reading from Keychain.
    case errorReadingFromKeychain(OSStatus)
    /// Could not create public key.
    case errorCreatingPublicKey
    /// Could not get public key data (external representation).
    case errorGettingPublicKeyData
    /// An error occurred when adding certificate to Keychain. Lookup the status on <https://osstatus.com>.
    case errorAddingCertificateToKeychain(status: OSStatus)
    /// The password is missing data.
    case malformedPasswordData
    /// No password found in Keychain.
    case noPasswordFound
    /// Could not add password to Keychain.
    case failedAddingPassword(OSStatus)
    /// Password already in Keychain.
    case duplicatePassword
    /// Could not update password in Keychain.
    case failedUpdatingPassword
    /// Could not delete password from Keychain.
    case failedDeletingPassword

    public var description: String {
        switch self {
        case .errorReadingFromKeychain(let status):
            "Could not read from Keychain (OSStatus: \(status))"
        case .errorCreatingPublicKey:
            "Could not create public key"
        case .errorGettingPublicKeyData:
            "Could not get public key data"
        case .errorAddingCertificateToKeychain(let status):
            "Unknown error occurred when adding certificate to Keychain (OSStatus: \(status))"
        case .malformedPasswordData:
            "The password is missing data"
        case .noPasswordFound:
            "No password found in Keychain"
        case .failedAddingPassword:
            "Could not add password to Keychain"
        case .duplicatePassword:
            "Password already in Keychain"
        case .failedUpdatingPassword:
            "Could not update password in Keychain"
        case .failedDeletingPassword:
            "Could not delete password from Keychain"
        }
    }

    public var errorDescription: String? { description }
}
