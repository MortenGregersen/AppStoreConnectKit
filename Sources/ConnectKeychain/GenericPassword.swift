//
//  GenericPassword.swift
//  ConnectKeychain
//
//  Created by Morten Bjerg Gregersen on 02/10/2025.
//

import Foundation

public struct GenericPassword: Equatable, Sendable {
    public let account: String
    public let label: String
    public let generic: Data
    public let value: Data

    public init(account: String, label: String, generic: Data, value: Data) {
        self.account = account
        self.label = label
        self.generic = generic
        self.value = value
    }
}
