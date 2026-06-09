import Bagbutik_Core
@testable import ConnectClient
import ConnectTestSupport
import Testing

@Suite("App Store Connect client")
struct AppStoreConnectClientTests {
    struct TestResponse: Codable, Equatable, Sendable {
        let value: String
    }

    struct TestPagedResponse: Codable, PagedResponse, Sendable {
        let data: [String]
        let links: PagedDocumentLinks
        let meta: PagingInformation?
    }

    @Test("Delegates decoded request")
    func delegatesDecodedRequest() async throws {
        let response = TestResponse(value: "OK")
        let request = Request<TestResponse, ErrorResponse>(path: "/v1/test", method: .get)
        let service = MockBagbutikService()
        service.setResponse(response, for: Endpoint(path: "/v1/test", method: .get))
        let client = AppStoreConnectClient(bagbutikService: service)

        let result = try await client.request(request)

        #expect(result == response)
    }

    @Test("Delegates empty request")
    func delegatesEmptyRequest() async throws {
        let request = Request<EmptyResponse, ErrorResponse>(path: "/v1/test", method: .delete)
        let service = MockBagbutikService()
        service.setResponse(EmptyResponse(), for: Endpoint(path: "/v1/test", method: .delete))
        let client = AppStoreConnectClient(bagbutikService: service)

        _ = try await client.request(request)
    }

    @Test("Delegates paged request")
    func delegatesPagedRequest() async throws {
        let response = TestPagedResponse(data: ["One"], links: .init(self: "/v1/test"), meta: nil)
        let request = Request<TestPagedResponse, ErrorResponse>(path: "/v1/test", method: .get)
        let service = MockBagbutikService()
        service.setResponse(response, for: Endpoint(path: "/v1/test", method: .get))
        let client = AppStoreConnectClient(bagbutikService: service)

        let result = try await client.requestAllPages(request)

        #expect(result.responses.map(\.data) == [["One"]])
        #expect(result.data == ["One"])
    }

    @Test("Delegates next page request")
    func delegatesNextPageRequest() async throws {
        let response = TestPagedResponse(data: ["One"], links: .init(self: "/v1/test"), meta: nil)
        let client = AppStoreConnectClient(bagbutikService: MockBagbutikService())

        let result = try await client.requestNextPage(for: response)

        #expect(result?.data == ["One"])
    }

    @Test("Delegates remaining page request")
    func delegatesRemainingPageRequest() async throws {
        let response = TestPagedResponse(data: ["One"], links: .init(self: "/v1/test"), meta: nil)
        let client = AppStoreConnectClient(bagbutikService: MockBagbutikService())

        let result = try await client.requestAllPages(for: response)

        #expect(result.responses.map(\.data) == [["One"]])
        #expect(result.data == ["One"])
    }
}
