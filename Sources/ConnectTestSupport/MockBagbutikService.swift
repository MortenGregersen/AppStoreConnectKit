//
//  MockBagbutikService.swift
//  AppStoreConnectKit
//
//  Created by Morten Bjerg Gregersen on 03/10/2025.
//

import Bagbutik_Core
import ConnectClient
import Foundation

public class MockBagbutikService: BagbutikServiceProtocol {
    private(set) var responseDataByEndpoint = [Endpoint: Data]()
    private(set) var errorResponseDataByEndpoint = [Endpoint: Data]()
    private(set) var requestBodyJsons = [String]()
    private var endpointsCalled = 0
    fileprivate var allEndpointsCalled: Bool { endpointsCalled == responseDataByEndpoint.count + errorResponseDataByEndpoint.count }

    public init() {}

    public func setResponse(_ response: some Encodable, for endpoint: Endpoint) {
        responseDataByEndpoint[endpoint] = try! JSONEncoder().encode(response)
    }

    public func setErrorResponse(_ errorResponse: some Encodable, for endpoint: Endpoint) {
        errorResponseDataByEndpoint[endpoint] = try! JSONEncoder().encode(errorResponse)
    }

    public func request<T>(_ request: Request<T, ErrorResponse>) async throws -> T where T: Decodable {
        try decodeResponseData(for: request).get()
    }

    public func requestAllPages<T>(_ request: Request<T, ErrorResponse>) async throws -> (responses: [T], data: [T.Data]) where T: PagedResponse, T: Decodable {
        let response = try decodeResponseData(for: request).get()
        return (responses: [response], data: response.data)
    }

    public func requestNextPage<T>(for response: T) async throws -> T? where T: PagedResponse, T: Decodable {
        response
    }

    public func requestAllPages<T>(for response: T) async throws -> (responses: [T], data: [T.Data]) where T: PagedResponse, T: Decodable {
        (responses: [response], data: response.data)
    }

    private func decodeResponseData<T>(for request: Request<T, ErrorResponse>) -> Result<T, Error> where T: Decodable {
        if let jsonData = request.requestBody?.jsonData,
           let json = try? JSONSerialization.jsonObject(with: jsonData, options: []),
           let prettyJsonData = try? JSONSerialization.data(withJSONObject: json, options: [.sortedKeys, .prettyPrinted]),
           let requestBodyJson = String(data: prettyJsonData, encoding: .utf8) {
            requestBodyJsons.append(requestBodyJson)
        }
        endpointsCalled += 1
        let endpoint = Endpoint(path: request.path, method: request.method)
        if let responseData = responseDataByEndpoint[endpoint] {
            return .success(try! JSONDecoder().decode(T.self, from: responseData))
        } else if let errorResponseData = errorResponseDataByEndpoint[endpoint] {
            return .failure(try! JSONDecoder().decode(ErrorResponse.self, from: errorResponseData))
        } else {
            fatalError("Missing response data and error data for endpoint: \(endpoint.method) \(endpoint.path)")
        }
    }
}

public struct Endpoint: Hashable {
    let path: String
    let method: HTTPMethod

    public init(path: String, method: HTTPMethod) {
        self.path = path
        self.method = method
    }
}
