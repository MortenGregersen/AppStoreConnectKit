//
//  FetchingState.swift
//  ConnectCore
//
//  Created by Morten Bjerg Gregersen on 02/10/2025.
//

import Foundation

public enum FetchingState<T> {
    case fetching
    case fetched(T)
    case error(ConnectError)
}

extension FetchingState: Equatable where T: Equatable {}

