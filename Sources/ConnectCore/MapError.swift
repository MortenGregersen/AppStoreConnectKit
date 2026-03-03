//
//  MapError.swift
//  ConnectCore
//
//  Created by Morten Bjerg Gregersen on 02/10/2025.
//

import Bagbutik_Core
import Foundation

/**
 Map any error to an `ConnectError`.

 If the error is unknown, and thus unhandled a stack trace is included.

 - Parameters:
 - error: The error to map.
 - Returns: A `ConnectError`.
 */
public func mapErrorToConnectError(error: Error, parseAppStoreConnectErrors: Bool = true) -> ConnectError {
    if let connectError = error as? ConnectError {
        return connectError
    }
    if let firstError = (error as? ServiceError)?.errorResponse?.errors?.first {
        if let associatedErrors = firstError.meta?.associatedErrors?.values.flatMap({ $0 }) {
            return .errorWithAssociatedErrors(message: firstError.parsedDetail, associatedMessages: associatedErrors.map {
                if parseAppStoreConnectErrors { $0.parsedDetail }
                else { $0.detail ?? $0.title }
            }.unique)
        } else {
            return .simpleError(message: parseAppStoreConnectErrors
                ? firstError.parsedDetail
                : firstError.detail ?? firstError.title)
        }
    } else if let error = error as? ServiceError {
        return .simpleError(message: error.description!)
    } else if let error = error as? LocalizedError, let message = error.errorDescription {
        return .simpleError(message: message)
    } else if (error as NSError).domain == NSURLErrorDomain, (error as NSError).code == -999 {
        return .cancelled
    } else {
        let stackTrace = Thread.callStackSymbols.joined(separator: "\n")
        return .unhandledError(message: error.localizedDescription, stackTrace: stackTrace)
    }
}
