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

public struct Keychain: KeychainProtocol, Sendable {
    private let accessGroup: String

    public init(accessGroup: String) {
        self.accessGroup = accessGroup
    }

    init(accessGroup: String,
         secItemCopyMatching: @Sendable @escaping (CFDictionary, UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus = SecItemCopyMatching,
         secItemAdd: @Sendable @escaping (CFDictionary, UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus = SecItemAdd,
         secItemUpdate: @Sendable @escaping (CFDictionary, CFDictionary) -> OSStatus = SecItemUpdate,
         secItemDelete: @Sendable @escaping (CFDictionary) -> OSStatus = SecItemDelete,
         secIdentityCopyCertificate: @Sendable @escaping (SecIdentity, UnsafeMutablePointer<SecCertificate?>) -> OSStatus = SecIdentityCopyCertificate,
         secCertificateCopySerialNumberData: @Sendable @escaping (SecCertificate, UnsafeMutablePointer<Unmanaged<CFError>?>?) -> CFData? = SecCertificateCopySerialNumberData,
         secKeyCreateRandomKey: @Sendable @escaping (CFDictionary, UnsafeMutablePointer<Unmanaged<CFError>?>?) -> SecKey? = SecKeyCreateRandomKey,
         secKeyCopyPublicKey: @Sendable @escaping (SecKey) -> SecKey? = SecKeyCopyPublicKey,
         secKeyCopyExternalRepresentation: @Sendable @escaping (SecKey, UnsafeMutablePointer<Unmanaged<CFError>?>?) -> CFData? = SecKeyCopyExternalRepresentation) {
        self.accessGroup = accessGroup
        self.secItemCopyMatching = secItemCopyMatching
        self.secItemAdd = secItemAdd
        self.secItemUpdate = secItemUpdate
        self.secItemDelete = secItemDelete
        self.secIdentityCopyCertificate = secIdentityCopyCertificate
        self.secCertificateCopySerialNumberData = secCertificateCopySerialNumberData
        self.secKeyCreateRandomKey = secKeyCreateRandomKey
        self.secKeyCopyPublicKey = secKeyCopyPublicKey
        self.secKeyCopyExternalRepresentation = secKeyCopyExternalRepresentation
    }

    public func addCertificate(certificate: SecCertificate, named name: String) throws {
        let addquery: NSDictionary = [kSecClass: kSecClassCertificate,
                                      kSecValueRef: certificate,
                                      kSecAttrLabel: name]
        let addStatus = secItemAdd(addquery, nil)
        guard addStatus == errSecSuccess || addStatus == errSecDuplicateItem else {
            throw KeychainError.errorAddingCertificateToKeychain(status: addStatus)
        }
    }

    public func hasCertificate(serialNumber: String) async throws -> Bool {
        let secItemCopyMatching = secItemCopyMatching
        let secIdentityCopyCertificate = secIdentityCopyCertificate
        return try await Task.detached {
            var copyResult: CFTypeRef?
            let statusCopyingIdentities = secItemCopyMatching([
                kSecClass: kSecClassIdentity,
                kSecMatchLimit: kSecMatchLimitAll,
                kSecReturnRef: true,
            ] as NSDictionary, &copyResult)
            guard statusCopyingIdentities != errSecItemNotFound else {
                return false
            }
            guard statusCopyingIdentities == errSecSuccess, let identities = copyResult as? [SecIdentity] else {
                throw KeychainError.errorReadingFromKeychain(statusCopyingIdentities)
            }
            let serialNumbersInKeychain: [String] = try identities.compactMap { identity in
                var certificate: SecCertificate?
                let statusCopyingCertificate = secIdentityCopyCertificate(identity, &certificate)
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
        let statusCopyingIdentities = secItemCopyMatching([
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
            throw KeychainError.errorReadingFromKeychain(statusCopyingIdentities)
        }
        let serialNumbersInKeychain: [String] = try identities.compactMap { identity in
            var certificate: SecCertificate?
            let statusCopyingCertificate = secIdentityCopyCertificate(identity, &certificate)
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
        guard let privateKey = secKeyCreateRandomKey(parameters, &error) else {
            throw error!.takeRetainedValue() as Error
        }
        return privateKey
    }

    public func createPublicKey(from privateKey: SecKey) throws -> (key: SecKey, data: Data) {
        guard let publicKey = secKeyCopyPublicKey(privateKey) else {
            throw KeychainError.errorCreatingPublicKey
        }
        var error: Unmanaged<CFError>?
        guard let publicKeyData = secKeyCopyExternalRepresentation(publicKey, &error) else {
            throw KeychainError.errorGettingPublicKeyData
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
        query.addEntries(from: dataProtectionAttributes)
        if let account {
            query[kSecAttrAccount] = account
        }
        var items: CFTypeRef?
        let status = secItemCopyMatching(query, &items)
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
        query.addEntries(from: dataProtectionAttributes)
        let status = secItemAdd(query, nil)
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
        query.addEntries(from: dataProtectionAttributes)
        let attributesToUpdate: NSMutableDictionary = [
            kSecAttrLabel: password.label,
            kSecAttrGeneric: password.generic,
            kSecValueData: password.value,
        ]
        attributesToUpdate.addEntries(from: dataProtectionAttributes)
        let status = secItemUpdate(query, attributesToUpdate)
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
        query.addEntries(from: dataProtectionAttributes)
        let status = secItemDelete(query)
        guard status == errSecSuccess else {
            throw KeychainError.failedDeletingPassword
        }
    }

    private var dataProtectionAttributes: [AnyHashable: Any] {
        [
            kSecUseDataProtectionKeychain: true,
            kSecAttrAccessGroup: accessGroup,
            kSecAttrSynchronizable: true,
        ]
    }

    var secItemCopyMatching = SecItemCopyMatching
    var secItemAdd = SecItemAdd
    var secItemUpdate = SecItemUpdate
    var secItemDelete = SecItemDelete
    var secIdentityCopyCertificate = SecIdentityCopyCertificate
    var secCertificateCopySerialNumberData = SecCertificateCopySerialNumberData
    var secKeyCreateRandomKey = SecKeyCreateRandomKey
    var secKeyCopyPublicKey = SecKeyCopyPublicKey
    var secKeyCopyExternalRepresentation = SecKeyCopyExternalRepresentation
}

public extension Keychain {
    static func forPreview() -> Keychain {
        .init(accessGroup: "AppStoreConnectKit.Keychain-Preview")
    }
}
