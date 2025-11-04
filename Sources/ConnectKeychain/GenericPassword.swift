//
//  GenericPassword.swift
//  ConnectKeychain
//
//  Created by Morten Bjerg Gregersen on 02/10/2025.
//

import Foundation

/// Struct representing a generic password stored in the keychain.
public struct GenericPassword: Equatable, Sendable {
    /// The account associated with the generic password.
    public let account: String
    /// The label for the generic password.
    public let label: String
    /// The generic data associated with the password.
    public let generic: Data
    /// The actual password data.
    public let value: Data

    /**
     Initializes a new instance of `GenericPassword`.

     - Parameters:
        - account: The account associated with the generic password.
        - label: The label for the generic password.
        - generic: The generic data associated with the password.
        - value: The actual password data.
     */
    public init(account: String, label: String, generic: Data, value: Data) {
        self.account = account
        self.label = label
        self.generic = generic
        self.value = value
    }
}
