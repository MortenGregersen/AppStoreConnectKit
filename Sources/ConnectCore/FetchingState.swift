//
//  FetchingState.swift
//  ConnectCore
//
//  Created by Morten Bjerg Gregersen on 02/10/2025.
//

import Foundation

/// Enumeration representing the state of a fetching operation.
public enum FetchingState<T> {
    /// The fetching operation is in progress.
    case fetching
    /// The fetching operation completed successfully with the fetched data.
    case fetched(T)
    /// The fetching operation failed with an error.
    case error(ConnectError)
}

extension FetchingState: Equatable where T: Equatable {}
