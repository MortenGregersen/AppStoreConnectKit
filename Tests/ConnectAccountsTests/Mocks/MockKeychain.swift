//
//  MockKeychain.swift
//  AppStoreConnectKit
//
//  Created by Morten Bjerg Gregersen on 03/10/2025.
//

import ConnectKeychain
import Foundation

final class MockKeychain: KeychainProtocol, @unchecked Sendable {
    // MARK: SecItemCopyMatching

    var keychainLookup: @Sendable (_ query: CFDictionary, _ result: UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus = { _, _ in errSecSuccess }

    // MARK: SecItemAdd

    private(set) var parametersForAdd: [[String: Any]] = []
    var returnStatusForAdd: OSStatus = errSecSuccess

    // MARK: SecItemUpdate

    private(set) var parametersForUpdate: [[String: Any]] = []
    var returnStatusForUpdate: OSStatus = errSecSuccess

    // MARK: SecItemDelete

    private(set) var parametersForDelete: [[String: Any]] = []
    var returnStatusForDelete: OSStatus = errSecSuccess

    // MARK: SecKeyCreateRandomKey

    private(set) var parametersForCreateRandomKey: [[String: Any]] = []
    var createRandomKeyShouldSucceed = true

    // MARK: SecKeyCopyPublicKey

    var publicKeyToReturn: SecKey?
    var copyPublicKeyShouldSucceed = true

    // MARK: SecKeyCopyExternalRepresentation

    var copyPublicKeyDataShouldSucceed = true

    // MARK: Certificates in Keychain

    var serialNumbersForCertificatesInKeychain: [String] = []

    // MARK: Generic passwords in Keychain

    var genericPasswordsInKeychain: [GenericPassword] = []

    lazy var keychain: Keychain = .init(
        secItemCopyMatching: keychainLookup,
        secItemAdd: { @Sendable parameters, _ in
            self.parametersForAdd.append(parameters as! [String: Any])
            return self.returnStatusForAdd
        },
        secItemUpdate: { @Sendable parameters, _ in
            self.parametersForUpdate.append(parameters as! [String: Any])
            return self.returnStatusForUpdate
        },
        secItemDelete: { @Sendable parameters in
            self.parametersForDelete.append(parameters as! [String: Any])
            return self.returnStatusForDelete
        },
        secKeyCreateRandomKey: { @Sendable parameters, errorPointer in
            self.parametersForCreateRandomKey.append(parameters as! [String: Any])
            guard self.createRandomKeyShouldSucceed else {
                let error = CFErrorCreate(nil, "SecKeyCreateRandomKey" as CFString, -1, nil)!
                errorPointer?.initialize(to: Unmanaged.passRetained(error))
                return nil
            }
            return SecKeyCreateRandomKey(parameters, errorPointer)
        },
        secKeyCopyPublicKey: { @Sendable privateKey in
            guard self.copyPublicKeyShouldSucceed else {
                return nil
            }
            if let publicKeyToReturn = self.publicKeyToReturn {
                return publicKeyToReturn
            }
            return SecKeyCopyPublicKey(privateKey)
        },
        secKeyCopyExternalRepresentation: { @Sendable publicKey, errorPointer in
            guard self.copyPublicKeyDataShouldSucceed else {
                let error = CFErrorCreate(nil, "SecKeyCopyExternalRepresentation" as CFString, -1, nil)!
                errorPointer?.initialize(to: Unmanaged.passRetained(error))
                return nil
            }
            return SecKeyCopyExternalRepresentation(publicKey, errorPointer)
        }
    )

    func addCertificate(certificate: SecCertificate, named name: String) throws {
        try keychain.addCertificate(certificate: certificate, named: name)
    }

    func hasCertificate(serialNumber: String) async throws -> Bool {
        serialNumbersForCertificatesInKeychain.contains(serialNumber)
    }

    func hasCertificates(serialNumbers: [String]) throws -> [String: Bool] {
        serialNumbers.reduce(into: [:]) { result, serialNumber in
            result[serialNumber] = serialNumbersForCertificatesInKeychain.contains(serialNumber)
        }
    }

    func createPrivateKey(labeled label: String) throws -> SecKey {
        try keychain.createPrivateKey(labeled: label)
    }

    func createPublicKey(from privateKey: SecKey) throws -> (key: SecKey, data: Data) {
        try keychain.createPublicKey(from: privateKey)
    }

    func getGenericPassword(forService service: String, account: String) throws -> GenericPassword? {
        genericPasswordsInKeychain.first { $0.account == account }
    }

    func listGenericPasswords(forService service: String) throws -> [GenericPassword] {
        genericPasswordsInKeychain
    }

    func addGenericPassword(forService service: String, password: GenericPassword) throws {
        try keychain.addGenericPassword(forService: service, password: password)
        genericPasswordsInKeychain.append(password)
    }

    func updateGenericPassword(forService service: String, password: GenericPassword) throws {
        try keychain.updateGenericPassword(forService: service, password: password)
    }

    func deleteGenericPassword(forService service: String, password: GenericPassword) throws {
        try keychain.deleteGenericPassword(forService: service, password: password)
    }
}
