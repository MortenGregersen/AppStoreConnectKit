//
//  AppStoreConnectClient.swift
//  ConnetClient
//
//  Created by Morten Bjerg Gregersen on 08/05/2025.
//

import Bagbutik_Core
import Foundation

/// A client for interacting with the App Store Connect API.
@Observable
public final class AppStoreConnectClient: Sendable {
    private let bagbutikService: BagbutikServiceProtocol

    /**
     Initializes a new instance of `AppStoreConnectClient` with the provided JWT and fetch data closure.

     - Parameters:
        - jwt: The JWT used for authentication.
        - fetchData: A closure that fetches data for a given URLRequest.
     */
    public convenience init(jwt: JWT, fetchData: @escaping @Sendable FetchData) {
        self.init(bagbutikService: BagbutikService(jwt: jwt, fetchData: fetchData))
    }

    /**
     Initializes a new instance of `AppStoreConnectClient` with the provided `BagbutikServiceProtocol`.

     - Parameter bagbutikService: An instance conforming to `BagbutikServiceProtocol`.
     */
    public init(bagbutikService: BagbutikServiceProtocol) {
        self.bagbutikService = bagbutikService
    }

    /**
     Sends a request to the App Store Connect API and returns the decoded response.

     - Parameter request: A `Request` object representing the API request.
     - Returns: The decoded response of type `T`.
     */
    public nonisolated(nonsending)
    func request<T>(_ request: Request<T, ErrorResponse>) async throws -> T
        where T: Decodable & Sendable {
        try await bagbutikService.request(request)
    }

    /**
     Sends a request to the App Store Connect API that expects no response body.

     - Parameter request: A `Request` object representing the API request.
     - Returns: An `EmptyResponse` indicating success.
     */
    @discardableResult public nonisolated(nonsending)
    func request(_ request: Request<EmptyResponse, ErrorResponse>) async throws -> EmptyResponse {
        try await bagbutikService.request(request)
    }

    /**
     Sends a paginated request to the App Store Connect API and returns all pages of the decoded response.

     - Parameter request: A `Request` object representing the API request.
     - Returns: A tuple containing an array of all responses and an array of all data items.
     */
    public nonisolated(nonsending)
    func requestAllPages<T>(_ request: Request<T, ErrorResponse>) async throws -> (responses: [T], data: [T.Data])
        where T: Decodable & PagedResponse & Sendable {
        try await bagbutikService.requestAllPages(request)
    }

    /**
     Sends a request to fetch the next page of a paginated response.

     - Parameter response: The previous paginated response.
     - Returns: The next page of the response, or `nil` if there are no more pages.
     */
    public nonisolated(nonsending)
    func requestNextPage<T>(for response: T) async throws -> T?
        where T: Decodable & PagedResponse & Sendable {
        try await bagbutikService.requestNextPage(for: response)
    }

    /**
     Sends requests to fetch all remaining pages of a paginated response.

     - Parameter response: The previous paginated response.
     - Returns: A tuple containing an array of all responses and an array of all data items.
     */
    public nonisolated(nonsending)
    func requestAllPages<T>(for response: T) async throws -> (responses: [T], data: [T.Data])
        where T: Decodable & PagedResponse & Sendable, T.Data: Sendable {
        try await bagbutikService.requestAllPages(for: response)
    }
}

public extension AppStoreConnectClient {
    /// An `AppStoreConnectClient` instance configured for use in previews and tests..
    static func forPreview() -> AppStoreConnectClient {
        AppStoreConnectClient(bagbutikService: PreviewBagbutikService())
    }
}

/// A protocol defining the necessary methods for a Bagbutik service.
public protocol BagbutikServiceProtocol: Sendable {
    func request<T>(_ request: Request<T, ErrorResponse>) async throws -> T
        where T: Decodable & Sendable
    @discardableResult func request(_ request: Request<EmptyResponse, ErrorResponse>) async throws -> EmptyResponse
    func requestAllPages<T>(_ request: Request<T, ErrorResponse>) async throws -> (responses: [T], data: [T.Data])
        where T: Decodable & PagedResponse & Sendable
    func requestNextPage<T>(for response: T) async throws -> T?
        where T: Decodable & PagedResponse & Sendable
    func requestAllPages<T>(for response: T) async throws -> (responses: [T], data: [T.Data])
        where T: Decodable & PagedResponse & Sendable, T.Data: Sendable
}

/// Conform BagbutikService to BagbutikServiceProtocol
extension BagbutikService: BagbutikServiceProtocol {}

/// A Bagbutik service implementation for use in previews and tests (throws errors for all requests).
final class PreviewBagbutikService: BagbutikServiceProtocol {
    func request<T: Decodable>(_ request: Request<T, ErrorResponse>) async throws -> T {
        throw NSError(domain: "PreviewBagbutikService", code: 0, userInfo: nil)
    }

    @discardableResult func request(_ request: Request<EmptyResponse, ErrorResponse>) async throws -> EmptyResponse {
        throw NSError(domain: "PreviewBagbutikService", code: 0, userInfo: nil)
    }

    func requestAllPages<T: Decodable & PagedResponse>(_ request: Request<T, ErrorResponse>) async throws -> (responses: [T], data: [T.Data]) {
        throw NSError(domain: "PreviewBagbutikService", code: 0, userInfo: nil)
    }

    func requestNextPage<T: Decodable & PagedResponse>(for response: T) async throws -> T? {
        throw NSError(domain: "PreviewBagbutikService", code: 0, userInfo: nil)
    }

    func requestAllPages<T>(for response: T) async throws -> (responses: [T], data: [T.Data])
        where T: Decodable & PagedResponse & Sendable {
        throw NSError(domain: "PreviewBagbutikService", code: 0, userInfo: nil)
    }
}
