//
//  ConnectError.swift
//  ConnectCore
//
//  Created by Morten Bjerg Gregersen on 02/10/2025.
//

import Foundation

/// A mapped error for easier logging.
public enum ConnectError: Error, Equatable {
    /// A simple error with just a message.
    case simpleError(message: String)
    /// An error which has one or more associated/sub errors.
    case errorWithAssociatedErrors(message: String, associatedMessages: [String])
    /// The actions was cancelled
    case cancelled
    /// An unhandled error with a message and a stack trace.
    case unhandledError(message: String, stackTrace: String)

    public var message: String {
        switch self {
        case .simpleError(let message), .unhandledError(let message, _):
            return message
        case .cancelled:
            return "Cancelled"
        case .errorWithAssociatedErrors(let message, associatedMessages: let associatedMessages):
            return message + "\n" + associatedMessages.map { "• \($0)" }.joined(separator: "\n")
        }
    }
}
