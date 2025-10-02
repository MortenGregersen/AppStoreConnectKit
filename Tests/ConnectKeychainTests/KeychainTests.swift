import ConnectKeychain
import XCTest

final class KeychainTests: XCTestCase {
    // MARK: List generic passwords

    func testListGenericPasswords() throws {
        let genericPassword = GenericPassword(account: "P9M252746H", label: "Apple", generic: Data("82067982-6b3b-4a48-be4f-5b10b373c5f2".utf8), value: Data("""
        -----BEGIN PRIVATE KEY-----
        MIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQgevZzL1gdAFr88hb2
        OF/2NxApJCzGCEDdfSp6VQO30hyhRANCAAQRWz+jn65BtOMvdyHKcvjBeBSDZH2r
        1RTwjmYSi9R/zpBnuQ4EiMnCqfMPWiZqB4QdbAd0E7oH50VpuZ1P087G
        -----END PRIVATE KEY-----
        """.utf8))
        let service = "AppDab"
        let keychain = Keychain(secItemCopyMatching: { _, result in
            result?.pointee = [[
                kSecAttrLabel: genericPassword.label,
                kSecAttrAccount: genericPassword.account,
                kSecAttrGeneric: genericPassword.generic,
                kSecValueData: genericPassword.value
            ]] as CFTypeRef
            return errSecSuccess
        })
        XCTAssertEqual(try keychain.listGenericPasswords(forService: service), [genericPassword])
    }

    func testListGenericPasswords_NoPasswordFound() {
        let keychain = Keychain(secItemCopyMatching: { _, _ in errSecItemNotFound })
        XCTAssertEqual(try keychain.listGenericPasswords(forService: "AppDab"), [])
    }

    func testListGenericPasswords_Unknown() {
        let keychain = Keychain(secItemCopyMatching: { _, _ in errSecParam })
        XCTAssertThrowsError(try keychain.listGenericPasswords(forService: "AppDab")) { error in
            XCTAssertEqual(error as! KeychainError, .errorReadingFromKeychain(errSecParam))
        }
    }

    func testListGenericPasswords_InvalidPassword() throws {
        let keychain = Keychain(secItemCopyMatching: { query, result in
            let query = query as NSDictionary
            if query[kSecReturnRef] != nil {
                result?.pointee = ["item"] as CFTypeRef
            } else {
                result?.pointee = [:] as CFTypeRef
            }
            return errSecSuccess
        })
        XCTAssertThrowsError(try keychain.listGenericPasswords(forService: "AppDab")) { error in
            XCTAssertEqual(error as! KeychainError, .errorReadingFromKeychain(errSecSuccess))
        }
    }

    // MARK: Update generic password

    func testAddGenericPassword() {
        let keychain = Keychain(secItemAdd: { _, _ in errSecSuccess })
        let genericPassword = GenericPassword(account: "", label: "", generic: Data(), value: Data())
        XCTAssertNoThrow(try keychain.addGenericPassword(forService: "AppDab", password: genericPassword))
    }

    func testAddGenericPassword_Duplicate() {
        let keychain = Keychain(secItemAdd: { _, _ in errSecDuplicateItem })
        let genericPassword = GenericPassword(account: "", label: "", generic: Data(), value: Data())
        XCTAssertThrowsError(try keychain.addGenericPassword(forService: "AppDab", password: genericPassword)) { error in
            XCTAssertEqual(error as! KeychainError, .duplicatePassword)
        }
    }

    func testAddGenericPassword_Unknown() {
        let status = errSecParam
        let keychain = Keychain(secItemAdd: { _, _ in status })
        let genericPassword = GenericPassword(account: "", label: "", generic: Data(), value: Data())
        XCTAssertThrowsError(try keychain.addGenericPassword(forService: "AppDab", password: genericPassword)) { error in
            XCTAssertEqual(error as! KeychainError, .failedAddingPassword(status))
        }
    }

    // MARK: Update generic password

    func testUpdateGenericPassword() {
        let keychain = Keychain(secItemUpdate: { _, _ in errSecSuccess })
        let genericPassword = GenericPassword(account: "", label: "", generic: Data(), value: Data())
        XCTAssertNoThrow(try keychain.updateGenericPassword(forService: "AppDab", password: genericPassword))
    }

    func testUpdateGenericPassword_Unknown() {
        let keychain = Keychain(secItemUpdate: { _, _ in errSecParam })
        let genericPassword = GenericPassword(account: "", label: "", generic: Data(), value: Data())
        XCTAssertThrowsError(try keychain.updateGenericPassword(forService: "AppDab", password: genericPassword)) { error in
            XCTAssertEqual(error as! KeychainError, .failedUpdatingPassword)
        }
    }

    // MARK: Delete generic password

    func testDeleteGenericPassword() {
        let keychain = Keychain(secItemDelete: { _ in errSecSuccess })
        let genericPassword = GenericPassword(account: "", label: "", generic: Data(), value: Data())
        XCTAssertNoThrow(try keychain.deleteGenericPassword(forService: "AppDab", password: genericPassword))
    }

    func testDeleteGenericPassword_Unknown() {
        let keychain = Keychain(secItemDelete: { _ in errSecParam })
        let genericPassword = GenericPassword(account: "", label: "", generic: Data(), value: Data())
        XCTAssertThrowsError(try keychain.deleteGenericPassword(forService: "AppDab", password: genericPassword)) { error in
            XCTAssertEqual(error as! KeychainError, .failedDeletingPassword)
        }
    }

    // MARK: Keychain error

    func testKeychainErrorDescription() {
        XCTAssertEqual(KeychainError.noPasswordFound.description, "No password found in Keychain")
        XCTAssertEqual(KeychainError.failedAddingPassword(errSecDuplicateItem).description, "Could not add password to Keychain")
        XCTAssertEqual(KeychainError.wrongPassphraseForP12.description, "Wrong passphrase for encrypted certificate and private key")
        XCTAssertEqual(KeychainError.errorImportingP12.description, "Could not import certificate and private key")
        XCTAssertEqual(KeychainError.unknown(status: errSecNoSuchAttr).description, "Unknown error occurred when interacting with Keychain (OSStatus: \(errSecNoSuchAttr))")
    }
}

extension GenericPassword: Equatable {
    public static func == (lhs: GenericPassword, rhs: GenericPassword) -> Bool {
        lhs.account == rhs.account
            && lhs.label == rhs.label
            && lhs.generic == rhs.generic
            && lhs.value == rhs.value
    }
}
