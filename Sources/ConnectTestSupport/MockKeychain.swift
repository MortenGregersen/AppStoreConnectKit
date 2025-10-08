//
//  MockKeychain.swift
//  AppStoreConnectKit
//
//  Created by Morten Bjerg Gregersen on 03/10/2025.
//

@testable import ConnectKeychain
import Foundation

public final class MockKeychain: KeychainProtocol, @unchecked Sendable {
    public init() {}

    // MARK: Configuration flags

    public var returnStatusForAdd: OSStatus = errSecSuccess

    // Control return value of SecItemDelete
    public var returnStatusForDelete: OSStatus = errSecSuccess

    // Control whether private key creation should succeed.
    public var createRandomKeyShouldSucceed = true

    // Control whether public key derivation should succeed.
    public var copyPublicKeyShouldSucceed = true

    // Control whether public key external representation should succeed.
    public var copyPublicKeyDataShouldSucceed = true

    // MARK: Injected return values

    // If set, this data will be used as the external representation of the public key.
    public var publicKeyDataToReturn: Data?

    // MARK: Certificates in Keychain (purely in-memory simulation)

    public var serialNumbersForCertificatesInKeychain: [String] = []

    // MARK: Generic passwords in Keychain (purely in-memory simulation)

    public var genericPasswordsInKeychain: [GenericPassword] = []

    // MARK: KeychainProtocol

    public func addCertificate(certificate: SecCertificate, named name: String) throws {
        let serialNumber = (SecCertificateCopySerialNumberData(certificate, nil)! as Data).hexadecimalString.lowercased()
        serialNumbersForCertificatesInKeychain.append(serialNumber)
    }

    public func hasCertificate(serialNumber: String) async throws -> Bool {
        serialNumbersForCertificatesInKeychain.contains(serialNumber)
    }

    public func hasCertificates(serialNumbers: [String]) throws -> [String: Bool] {
        serialNumbers.reduce(into: [:]) { result, serialNumber in
            result[serialNumber] = serialNumbersForCertificatesInKeychain.contains(serialNumber)
        }
    }

    public func createPrivateKey(labeled label: String) throws -> SecKey {
        guard createRandomKeyShouldSucceed else {
            let error = CFErrorCreate(nil, "SecKeyCreateRandomKey" as CFString, -1, nil)! as Error
            throw error
        }
        let params: NSDictionary = [
            kSecAttrKeyType: kSecAttrKeyTypeRSA,
            kSecAttrKeySizeInBits: 2048,
            kSecAttrIsPermanent: false,
        ]
        var error: Unmanaged<CFError>?
        guard let key = SecKeyCreateRandomKey(params, &error) else {
            throw (error!.takeRetainedValue() as Error)
        }
        return key
    }

    public func createPublicKey(from privateKey: SecKey) throws -> (key: SecKey, data: Data) {
        guard copyPublicKeyShouldSucceed, let publicKey = SecKeyCopyPublicKey(privateKey) else {
            throw KeychainError.errorCreatingPublicKey
        }
        guard copyPublicKeyDataShouldSucceed else {
            throw KeychainError.errorGettingPublicKeyData
        }
        guard let publicKeyData = publicKeyDataToReturn else {
            let error = CFErrorCreate(nil, "MockKeychain" as CFString, -1, [kCFErrorDescriptionKey as String: "No publicKeyDataToReturn injected"] as CFDictionary)! as Error
            throw error
        }
        return (key: publicKey, data: publicKeyData)
    }

    public func getGenericPassword(forService service: String, account: String) throws -> GenericPassword? {
        genericPasswordsInKeychain.first { $0.account == account }
    }

    public func listGenericPasswords(forService service: String) throws -> [GenericPassword] {
        genericPasswordsInKeychain
    }

    public func addGenericPassword(forService service: String, password: GenericPassword) throws {
        guard returnStatusForAdd == errSecSuccess else {
            if returnStatusForAdd == errSecDuplicateItem {
                throw KeychainError.duplicatePassword
            } else {
                throw KeychainError.failedAddingPassword(returnStatusForAdd)
            }
        }
        if genericPasswordsInKeychain.contains(where: { $0.account == password.account && $0.label == password.label }) {
            throw KeychainError.duplicatePassword
        }
        genericPasswordsInKeychain.append(password)
    }

    public func updateGenericPassword(forService service: String, password: GenericPassword) throws {
        guard let index = genericPasswordsInKeychain.firstIndex(where: { $0.account == password.account }) else {
            throw KeychainError.failedUpdatingPassword
        }
        genericPasswordsInKeychain[index] = password
    }

    public func deleteGenericPassword(forService service: String, password: GenericPassword) throws {
        if returnStatusForDelete != errSecSuccess {
            throw KeychainError.failedDeletingPassword
        }
        guard let index = genericPasswordsInKeychain.firstIndex(where: { $0.account == password.account }) else {
            throw KeychainError.failedDeletingPassword
        }
        genericPasswordsInKeychain.remove(at: index)
    }
}
