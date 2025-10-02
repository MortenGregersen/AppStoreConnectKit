//
//  KeychainError.swift
//  ConnectKeychain
//
//  Created by Morten Bjerg Gregersen on 02/10/2025.
//

import ConnectCore
import Foundation

public enum KeychainError: LocalizedError, Equatable {
    case errorReadingFromKeychain(OSStatus)
    case malformedPasswordData
    case noPasswordFound
    case failedAddingPassword(OSStatus)
    case duplicatePassword
    case failedUpdatingPassword
    case failedDeletingPassword
    case wrongPassphraseForP12
    case errorImportingP12
    case unknown(status: OSStatus)

    public var description: String {
        switch self {
        case .errorReadingFromKeychain(let status):
            "Could not read from Keychain (OSStatus: \(status))"
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
        case .wrongPassphraseForP12:
            "Wrong passphrase for encrypted certificate and private key"
        case .errorImportingP12:
            "Could not import certificate and private key"
        case .unknown(let status):
            "Unknown error occurred when interacting with Keychain (OSStatus: \(status))"
        }
    }

    public var errorDescription: String? { description }
}
