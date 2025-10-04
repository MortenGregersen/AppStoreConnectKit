//
//  MockKeychain.swift
//  AppStoreConnectKit
//
//  Created by Morten Bjerg Gregersen on 03/10/2025.
//

import ConnectKeychain
import Foundation

public final class MockKeychain: KeychainProtocol, @unchecked Sendable {
    public init() {}

    // MARK: SecItemCopyMatching

    public var keychainLookup: @Sendable (_ query: CFDictionary, _ result: UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus = { _, _ in errSecSuccess }

    // MARK: SecItemAdd

    public private(set) var parametersForAdd: [[String: Any]] = []
    public var returnStatusForAdd: OSStatus = errSecSuccess

    // MARK: SecItemUpdate

    public private(set) var parametersForUpdate: [[String: Any]] = []
    public var returnStatusForUpdate: OSStatus = errSecSuccess

    // MARK: SecItemDelete

    public private(set) var parametersForDelete: [[String: Any]] = []
    public var returnStatusForDelete: OSStatus = errSecSuccess

    // MARK: SecKeyCreateRandomKey

    public private(set) var parametersForCreateRandomKey: [[String: Any]] = []
    public var createRandomKeyShouldSucceed = true

    // MARK: SecKeyCopyPublicKey

    public var publicKeyToReturn: SecKey?
    public var copyPublicKeyShouldSucceed = true

    // MARK: SecKeyCopyExternalRepresentation

    public var copyPublicKeyDataShouldSucceed = true

    // MARK: Certificates in Keychain

    public var serialNumbersForCertificatesInKeychain: [String] = []

    // MARK: Generic passwords in Keychain

    public var genericPasswordsInKeychain: [GenericPassword] = []

    private lazy var keychain: Keychain = .init(
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

    public func addCertificate(certificate: SecCertificate, named name: String) throws {
        try keychain.addCertificate(certificate: certificate, named: name)
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
        try keychain.createPrivateKey(labeled: label)
    }

    public func createPublicKey(from privateKey: SecKey) throws -> (key: SecKey, data: Data) {
        try keychain.createPublicKey(from: privateKey)
    }

    public func getGenericPassword(forService service: String, account: String) throws -> GenericPassword? {
        genericPasswordsInKeychain.first { $0.account == account }
    }

    public func listGenericPasswords(forService service: String) throws -> [GenericPassword] {
        genericPasswordsInKeychain
    }

    public func addGenericPassword(forService service: String, password: GenericPassword) throws {
        try keychain.addGenericPassword(forService: service, password: password)
        genericPasswordsInKeychain.append(password)
    }

    public func updateGenericPassword(forService service: String, password: GenericPassword) throws {
        try keychain.updateGenericPassword(forService: service, password: password)
    }

    public func deleteGenericPassword(forService service: String, password: GenericPassword) throws {
        try keychain.deleteGenericPassword(forService: service, password: password)
    }
}
