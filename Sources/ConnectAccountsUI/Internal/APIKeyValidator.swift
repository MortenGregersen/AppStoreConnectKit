//
//  APIKeyValidator.swift
//  ConnectAccountsUI
//
//  Created by Morten Bjerg Gregersen on 27/10/2025.
//

/// Protocol for validating API key credentials.
@MainActor
public protocol APIKeyValidator: AnyObject {
    /**
     Validates the provided API key credentials.

     - Parameter credentials: The API key credentials to validate.
     */
    func validateKey(credentials: APIKeyCredentials) async throws
}
