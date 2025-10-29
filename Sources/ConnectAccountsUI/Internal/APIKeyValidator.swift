//
//  APIKeyValidator.swift
//  ConnectAccountsUI
//
//  Created by Morten Bjerg Gregersen on 27/10/2025.
//

/// Protocol for validating API key credentials.
public protocol APIKeyValidator: AnyObject {
    /**
     Validates the provided API key credentials.

     - Parameter credentials: The API key credentials to validate.
     */
    nonisolated(nonsending) func validateKey(credentials: APIKeyCredentials) async throws
}
