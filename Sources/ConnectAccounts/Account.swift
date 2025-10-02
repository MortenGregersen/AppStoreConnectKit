//
//  Account.swift
//  ConnectAccounts
//
//  Created by Morten Bjerg Gregersen on 20/05/2025.
//

import Foundation

public enum Account: Hashable, Identifiable, Sendable {
    case apiKey(APIKey)
    case demo

    public var id: String {
        switch self {
        case .apiKey(let apiKey): apiKey.id
        case .demo: "demo"
        }
    }

    public var name: String {
        switch self {
        case .apiKey(let apiKey): apiKey.name
        case .demo: "Demo"
        }
    }
}
