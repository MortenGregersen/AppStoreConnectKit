@testable import ConnectKeychain
import Foundation
import Testing

@MainActor @Suite("Keychain Tests", .tags(.keychain))
struct KeychainTests {
    // MARK: List generic passwords

    @Test("List generic passwords")
    func listGenericPasswords() throws {
        // Arrange
        let genericPassword = GenericPassword(account: "P9M252746H", label: "Apple", generic: Data("82067982-6b3b-4a48-be4f-5b10b373c5f2".utf8), value: Data("""
        -----BEGIN PRIVATE KEY-----
        MIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQgevZzL1gdAFr88hb2
        OF/2NxApJCzGCEDdfSp6VQO30hyhRANCAAQRWz+jn65BtOMvdyHKcvjBeBSDZH2r
        1RTwjmYSi9R/zpBnuQ4EiMnCqfMPWiZqB4QdbAd0E7oH50VpuZ1P087G
        -----END PRIVATE KEY-----
        """.utf8))
        let service = "AppDab"
        let keychain = Keychain(accessGroup: "Test", secItemCopyMatching: { _, result in
            result?.pointee = [[
                kSecAttrLabel: genericPassword.label,
                kSecAttrAccount: genericPassword.account,
                kSecAttrGeneric: genericPassword.generic,
                kSecValueData: genericPassword.value
            ]] as CFTypeRef
            return errSecSuccess
        })
        // Act
        let genericPasswords = try keychain.listGenericPasswords(forService: service)
        // Assert
        #expect(genericPasswords == [genericPassword])
    }

    @Test("List generic passwords - No password found")
    func listGenericPasswords_NoPasswordFound() throws{
        let keychain = Keychain(accessGroup: "Test", secItemCopyMatching: { _, _ in errSecItemNotFound })
        #expect(try keychain.listGenericPasswords(forService: "AppDab") == [])
    }

    @Test("List generic passwords - Unknown error")
    func listGenericPasswords_Unknown() {
        let keychain = Keychain(accessGroup: "Test", secItemCopyMatching: { _, _ in errSecParam })
        #expect(throws: KeychainError.errorReadingFromKeychain(errSecParam)) {
            try keychain.listGenericPasswords(forService: "AppDab")
        }
    }

    @Test("List generic passwords - Invalid password")
    func listGenericPasswords_InvalidPassword() throws {
        let keychain = Keychain(accessGroup: "Test", secItemCopyMatching: { query, result in
            let query = query as NSDictionary
            if query[kSecReturnRef] != nil {
                result?.pointee = ["item"] as CFTypeRef
            } else {
                result?.pointee = [:] as CFTypeRef
            }
            return errSecSuccess
        })
        #expect(throws: KeychainError.errorReadingFromKeychain(errSecSuccess)) {
            try keychain.listGenericPasswords(forService: "AppDab")
        }
    }

    // MARK: Add generic password

    @Test("Add generic password")
    func addGenericPassword() throws {
        let keychain = Keychain(accessGroup: "Test", secItemAdd: { _, _ in errSecSuccess })
        let genericPassword = GenericPassword(account: "", label: "", generic: Data(), value: Data())
        try keychain.addGenericPassword(forService: "AppDab", password: genericPassword)
    }

    #if os(macOS)
    @Test("Login Keychain works without app identity entitlements")
    func macOSLoginGenericPasswords() throws {
        // An unsigned command line tool receives this status when a generic
        // password query opts into the data protection or synchronized store.
        let password = GenericPassword(account: "test-account", label: "Test", generic: Data(), value: Data("secret".utf8))
        let keychain = Keychain(
            accessGroup: nil,
            storage: .macOSLogin,
            secItemCopyMatching: { query, result in
                let status = EntitlementGate.status(query)
                guard status == errSecSuccess else { return status }
                let attributes = query as NSDictionary
                if attributes[kSecReturnData] != nil {
                    result?.pointee = [
                        kSecAttrAccount: password.account,
                        kSecAttrLabel: password.label,
                        kSecAttrGeneric: password.generic,
                        kSecValueData: password.value,
                    ] as CFTypeRef
                } else {
                    result?.pointee = [[kSecAttrAccount: password.account]] as CFTypeRef
                }
                return errSecSuccess
            },
            secItemAdd: { query, _ in EntitlementGate.status(query) },
            secItemUpdate: { query, changes in
                let queryStatus = EntitlementGate.status(query)
                return queryStatus == errSecSuccess ? EntitlementGate.status(changes) : queryStatus
            },
            secItemDelete: { query in EntitlementGate.status(query) }
        )
        #expect(try keychain.listGenericPasswords(forService: "AppDabCLI") == [password])
        #expect(try keychain.getGenericPassword(forService: "AppDabCLI", account: password.account) == password)
        try keychain.addGenericPassword(forService: "AppDabCLI", password: password)
        try keychain.updateGenericPassword(forService: "AppDabCLI", password: password)
        try keychain.deleteGenericPassword(forService: "AppDabCLI", password: password)
        _ = Keychain.macOSLogin()
    }

    @Test("Login Keychain lists no accounts when the service has no items")
    func macOSLoginNoPasswords() throws {
        let keychain = Keychain(accessGroup: nil, storage: .macOSLogin, secItemCopyMatching: { _, _ in errSecItemNotFound })
        #expect(try keychain.listGenericPasswords(forService: "AppDabCLI").isEmpty)
    }

    @Test("Login Keychain rejects account metadata without an account identifier")
    func macOSLoginMalformedAccountMetadata() {
        let keychain = Keychain(accessGroup: nil, storage: .macOSLogin, secItemCopyMatching: { _, result in
            result?.pointee = [[:]] as CFTypeRef
            return errSecSuccess
        })
        #expect(throws: KeychainError.malformedPasswordData) {
            try keychain.listGenericPasswords(forService: "AppDabCLI")
        }
    }

    @Test("Login Keychain preserves a read failure")
    func macOSLoginReadFailure() {
        let keychain = Keychain(accessGroup: nil, storage: .macOSLogin, secItemCopyMatching: { _, _ in errSecParam })
        #expect(throws: KeychainError.errorReadingFromKeychain(errSecParam)) {
            try keychain.listGenericPasswords(forService: "AppDabCLI")
        }
    }

    @Test("Login Keychain rejects an incomplete password item")
    func macOSLoginIncompletePassword() {
        let keychain = Keychain(accessGroup: nil, storage: .macOSLogin, secItemCopyMatching: { _, result in
            result?.pointee = [
                kSecAttrAccount: "test-account",
                kSecAttrLabel: "Test",
            ] as CFTypeRef
            return errSecSuccess
        })
        #expect(throws: KeychainError.malformedPasswordData) {
            try keychain.getGenericPassword(forService: "AppDabCLI", account: "test-account")
        }
    }
    #endif

    @Test("Add generic password - Duplicate")
    func addGenericPassword_Duplicate() {
        let keychain = Keychain(accessGroup: "Test", secItemAdd: { _, _ in errSecDuplicateItem })
        let genericPassword = GenericPassword(account: "", label: "", generic: Data(), value: Data())
        #expect(throws: KeychainError.duplicatePassword) {
            try keychain.addGenericPassword(forService: "AppDab", password: genericPassword)
        }
    }

    @Test("Add generic password - Unknown error")
    func addGenericPassword_Unknown() {
        let status = errSecParam
        let keychain = Keychain(accessGroup: "Test", secItemAdd: { _, _ in status })
        let genericPassword = GenericPassword(account: "", label: "", generic: Data(), value: Data())
        #expect(throws: KeychainError.failedAddingPassword(status)) {
            try keychain.addGenericPassword(forService: "AppDab", password: genericPassword)
        }
    }

    // MARK: Update generic password

    @Test("Update generic password")
    func updateGenericPassword() throws {
        let keychain = Keychain(accessGroup: "Test", secItemUpdate: { _, _ in errSecSuccess })
        let genericPassword = GenericPassword(account: "", label: "", generic: Data(), value: Data())
        try keychain.updateGenericPassword(forService: "AppDab", password: genericPassword)
    }

    @Test("Update generic password - Unknown error")
    func updateGenericPassword_Unknown() {
        let keychain = Keychain(accessGroup: "Test", secItemUpdate: { _, _ in errSecParam })
        let genericPassword = GenericPassword(account: "", label: "", generic: Data(), value: Data())
        #expect(throws: KeychainError.failedUpdatingPassword) {
            try keychain.updateGenericPassword(forService: "AppDab", password: genericPassword)
        }
    }

    // MARK: Delete generic password

    @Test("Delete generic password")
    func deleteGenericPassword() throws {
        let keychain = Keychain(accessGroup: "Test", secItemDelete: { _ in errSecSuccess })
        let genericPassword = GenericPassword(account: "", label: "", generic: Data(), value: Data())
        try keychain.deleteGenericPassword(forService: "AppDab", password: genericPassword)
    }

    @Test("Delete generic password - Unknown error")
    func deleteGenericPassword_Unknown() {
        let keychain = Keychain(accessGroup: "Test", secItemDelete: { _ in errSecParam })
        let genericPassword = GenericPassword(account: "", label: "", generic: Data(), value: Data())
        #expect(throws: KeychainError.failedDeletingPassword) {
            try keychain.deleteGenericPassword(forService: "AppDab", password: genericPassword)
        }
    }
}

extension Tag {
    @Tag static var keychain: Self
}

#if os(macOS)
private enum EntitlementGate {
    static func status(_ query: CFDictionary) -> OSStatus {
        let attributes = query as NSDictionary
        if attributes[kSecUseDataProtectionKeychain] != nil || attributes[kSecAttrSynchronizable] != nil {
            return errSecMissingEntitlement
        }
        if attributes[kSecReturnData] != nil,
           attributes[kSecMatchLimit] as? String == kSecMatchLimitAll as String {
            return errSecParam
        }
        return errSecSuccess
    }
}
#endif
