//
//  Data+HexadecimalString.swift
//  ConnectKeychain
//
//  Created by Morten Bjerg Gregersen on 02/10/2025.
//

import Foundation

internal extension Data {
    var hexadecimalString: String {
        return self.map { String(format: "%02hhx", $0) }.joined()
    }
}

