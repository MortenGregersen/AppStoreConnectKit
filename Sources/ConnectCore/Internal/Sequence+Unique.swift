//
//  Sequence+Unique.swift
//  ConnectCore
//
//  Created by Morten Bjerg Gregersen on 02/10/2025.
//

import Foundation

extension Sequence where Iterator.Element: Hashable {
    var unique: [Iterator.Element] {
        var seen: Set<Iterator.Element> = []
        return filter {
            let result = seen.insert($0)
            return result.inserted
        }
    }
}
