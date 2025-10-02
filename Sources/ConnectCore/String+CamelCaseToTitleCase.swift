//
//  String+CamelCaseToTitleCase.swift
//  ConnectCore
//
//  Created by Morten Bjerg Gregersen on 02/10/2025.
//

import Foundation

extension String {
    var camelCaseToTitleCase: String {
        unicodeScalars.reduce("") {
            if CharacterSet.uppercaseLetters.contains($1) {
                if !$0.isEmpty {
                    return $0 + " " + String($1)
                }
            }
            return $0 + String($1)
        }
        .capitalized
    }

    var magicWordsFixed: String {
        replacingOccurrences(of: "Url", with: "URL")
    }
}
