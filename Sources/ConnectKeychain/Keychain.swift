//
//  Keychain.swift
//  ConnectKeychain
//
//  Created by Morten Bjerg Gregersen on 02/10/2025.
//

import Foundation

public protocol KeychainProtocol {
    func addCertificate(certificate: SecCertificate, named name: String) throws
    func hasCertificate(serialNumber: String) async throws -> Bool
    func hasCertificates(serialNumbers: [String]) throws -> [String: Bool]
    func createPrivateKey(labeled label: String) throws -> SecKey
    func createPublicKey(from privateKey: SecKey) throws -> (key: SecKey, data: Data)
    func getGenericPassword(forService service: String, account: String) throws -> GenericPassword?
    func listGenericPasswords(forService service: String) throws -> [GenericPassword]
    func addGenericPassword(forService service: String, password: GenericPassword) throws
    func updateGenericPassword(forService service: String, password: GenericPassword) throws
    func deleteGenericPassword(forService service: String, password: GenericPassword) throws
}

public struct Keychain: KeychainProtocol {
    public func addCertificate(certificate: SecCertificate, named name: String) throws {
        let addquery: NSDictionary = [kSecClass: kSecClassCertificate,
                                      kSecValueRef: certificate,
                                      kSecAttrLabel: name]
        let addStatus = SecItemAdd(addquery, nil)
        guard addStatus == errSecSuccess || addStatus == errSecDuplicateItem else {
            throw AddCertificateToKeychainError.errorAddingCertificateToKeychain(status: addStatus)
        }
    }

    public func hasCertificate(serialNumber: String) async throws -> Bool {
        try await Task.detached {
            var copyResult: CFTypeRef?
            let statusCopyingIdentities = SecItemCopyMatching([
                kSecClass: kSecClassIdentity,
                kSecMatchLimit: kSecMatchLimitAll,
                kSecReturnRef: true,
            ] as NSDictionary, &copyResult)
            guard statusCopyingIdentities != errSecItemNotFound else {
                return false
            }
            guard statusCopyingIdentities == errSecSuccess, let identities = copyResult as? [SecIdentity] else {
                throw CertificateError.errorReadingFromKeychain(statusCopyingIdentities)
            }
            let serialNumbersInKeychain: [String] = try identities.compactMap { identity in
                var certificate: SecCertificate?
                let statusCopyingCertificate = SecIdentityCopyCertificate(identity, &certificate)
                guard statusCopyingCertificate == errSecSuccess, let certificate else {
                    throw KeychainError.errorReadingFromKeychain(statusCopyingCertificate)
                }
                return (SecCertificateCopySerialNumberData(certificate, nil)! as Data).hexadecimalString.lowercased()
            }
            return serialNumbersInKeychain.contains(serialNumber.lowercased())
        }.value
    }

    public func hasCertificates(serialNumbers: [String]) throws -> [String: Bool] {
        var copyResult: CFTypeRef?
        let statusCopyingIdentities = SecItemCopyMatching([
            kSecClass: kSecClassIdentity,
            kSecMatchLimit: kSecMatchLimitAll,
            kSecReturnRef: true,
        ] as NSDictionary, &copyResult)
        if statusCopyingIdentities == errSecItemNotFound {
            return serialNumbers.reduce(into: [:]) { result, serialNumber in
                result[serialNumber] = false
            }
        }
        guard statusCopyingIdentities == errSecSuccess, let identities = copyResult as? [SecIdentity] else {
            throw CertificateError.errorReadingFromKeychain(statusCopyingIdentities)
        }
        let serialNumbersInKeychain: [String] = try identities.compactMap { identity in
            var certificate: SecCertificate?
            let statusCopyingCertificate = SecIdentityCopyCertificate(identity, &certificate)
            guard statusCopyingCertificate == errSecSuccess, let certificate else {
                throw KeychainError.errorReadingFromKeychain(statusCopyingCertificate)
            }
            return (SecCertificateCopySerialNumberData(certificate, nil)! as Data).hexadecimalString.lowercased()
        }
        return serialNumbers.reduce(into: [:]) { result, serialNumber in
            result[serialNumber] = serialNumbersInKeychain.contains(serialNumber.lowercased())
        }
    }

    public func createPrivateKey(labeled label: String) throws -> SecKey {
        let tag = label.data(using: .utf8)!
        let parameters: NSDictionary =
            [kSecAttrKeyType: kSecAttrKeyTypeRSA,
             kSecAttrKeySizeInBits: 2048,
             kSecAttrLabel: label,
             kSecPrivateKeyAttrs: [
                 kSecAttrIsPermanent: true,
                 kSecAttrApplicationTag: tag,
             ]]
        var error: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateRandomKey(parameters, &error) else {
            throw error!.takeRetainedValue() as Error
        }
        return privateKey
    }

    public func createPublicKey(from privateKey: SecKey) throws -> (key: SecKey, data: Data) {
        guard let publicKey = SecKeyCopyPublicKey(privateKey) else {
            throw CreateCertificateError.errorCreatingPublicKey
        }
        var error: Unmanaged<CFError>?
        guard let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, &error) else {
            throw CreateCertificateError.errorGettingPublicKeyData
        }
        return (key: publicKey, data: publicKeyData as Data)
    }

    public func getGenericPassword(forService service: String, account: String) throws -> GenericPassword? {
        try listGenericPasswords(forService: service, account: account).first
    }

    public func listGenericPasswords(forService service: String) throws -> [GenericPassword] {
        try listGenericPasswords(forService: service, account: nil)
    }

    private func listGenericPasswords(forService service: String, account: String? = nil) throws -> [GenericPassword] {
        let query: NSMutableDictionary = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecMatchLimit: kSecMatchLimitAll,
            kSecReturnAttributes: true,
            kSecReturnData: true,
        ]
        query.addEntries(from: Self.dataProtectionAttributes)
        if let account {
            query[kSecAttrAccount] = account
        }
        var items: CFTypeRef?
        let status = SecItemCopyMatching(query, &items)
        guard status != errSecItemNotFound else { return [] }
        guard status == errSecSuccess, let items = items as? [Any] else {
            throw KeychainError.errorReadingFromKeychain(status)
        }
        return try items.map { item -> GenericPassword in
            guard let item = item as? [String: Any],
                  let label = item[kSecAttrLabel as String] as? String,
                  let account = item[kSecAttrAccount as String] as? String,
                  let generic = item[kSecAttrGeneric as String] as? Data,
                  let value = item[kSecValueData as String] as? Data else {
                throw KeychainError.malformedPasswordData
            }
            return GenericPassword(account: account, label: label, generic: generic, value: value)
        }
    }

    public func addGenericPassword(forService service: String, password: GenericPassword) throws {
        let query: NSMutableDictionary = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: password.account,
            kSecAttrLabel: password.label,
            kSecAttrService: service,
            kSecAttrGeneric: password.generic,
            kSecValueData: password.value
        ]
        query.addEntries(from: Self.dataProtectionAttributes)
        let status = SecItemAdd(query, nil)
        guard status != errSecDuplicateItem else {
            throw KeychainError.duplicatePassword
        }
        guard status == errSecSuccess else {
            throw KeychainError.failedAddingPassword(status)
        }
    }

    public func updateGenericPassword(forService service: String, password: GenericPassword) throws {
        let query: NSMutableDictionary = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: password.account,
            kSecAttrService: service,
        ]
        query.addEntries(from: Self.dataProtectionAttributes)
        let attributesToUpdate: NSMutableDictionary = [
            kSecAttrLabel: password.label,
            kSecAttrGeneric: password.generic,
            kSecValueData: password.value,
        ]
        attributesToUpdate.addEntries(from: Self.dataProtectionAttributes)
        let status = SecItemUpdate(query, attributesToUpdate)
        guard status == errSecSuccess else {
            throw KeychainError.failedUpdatingPassword
        }
    }

    public func deleteGenericPassword(forService service: String, password: GenericPassword) throws {
        let query: NSMutableDictionary = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: password.account,
            kSecAttrService: service,
        ]
        query.addEntries(from: Self.dataProtectionAttributes)
        let status = SecItemDelete(query)
        guard status == errSecSuccess else {
            throw KeychainError.failedDeletingPassword
        }
    }

    private static var dataProtectionAttributes: [AnyHashable: Any] {
        [
            kSecUseDataProtectionKeychain: true,
            kSecAttrAccessGroup: "R7YA4RGA8U.app.AppDab.AppDab",
            kSecAttrSynchronizable: true,
        ]
    }
}
