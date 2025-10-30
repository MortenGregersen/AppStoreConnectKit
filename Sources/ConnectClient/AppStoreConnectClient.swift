//
//  AppStoreConnectClient.swift
//  ConnetClient
//
//  Created by Morten Bjerg Gregersen on 08/05/2025.
//

import Bagbutik_Core
import Foundation

@Observable
public final class AppStoreConnectClient: Sendable {
    private let bagbutikService: BagbutikServiceProtocol

    public convenience init(jwt: JWT, fetchData: @escaping @Sendable FetchData) {
        self.init(bagbutikService: BagbutikService(jwt: jwt, fetchData: fetchData))
    }

    public init(bagbutikService: BagbutikServiceProtocol) {
        self.bagbutikService = bagbutikService
    }

    public nonisolated(nonsending)
    func request<T>(_ request: Request<T, ErrorResponse>) async throws -> T
        where T: Decodable & Sendable {
        try await bagbutikService.request(request)
    }

    @discardableResult public nonisolated(nonsending)
    func request(_ request: Request<EmptyResponse, ErrorResponse>) async throws -> EmptyResponse {
        try await bagbutikService.request(request)
    }

    public nonisolated(nonsending)
    func requestAllPages<T>(_ request: Request<T, ErrorResponse>) async throws -> (responses: [T], data: [T.Data])
        where T: Decodable & PagedResponse & Sendable {
        try await bagbutikService.requestAllPages(request)
    }

    public nonisolated(nonsending)
    func requestNextPage<T>(for response: T) async throws -> T?
        where T: Decodable & PagedResponse & Sendable {
        try await bagbutikService.requestNextPage(for: response)
    }

    public nonisolated(nonsending)
    func requestAllPages<T>(for response: T) async throws -> (responses: [T], data: [T.Data])
        where T: Decodable & PagedResponse & Sendable, T.Data: Sendable {
        try await bagbutikService.requestAllPages(for: response)
    }
}

public extension AppStoreConnectClient {
    static func forPreview() -> AppStoreConnectClient {
        AppStoreConnectClient(bagbutikService: PreviewBagbutikService())
    }
}

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

extension BagbutikService: BagbutikServiceProtocol {}

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
