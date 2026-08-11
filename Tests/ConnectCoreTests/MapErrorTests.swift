import BagbutikCore
@testable import ConnectCore
import Foundation
import Testing

@Suite("Map errors", .tags(.errors))
struct MapErrorTests {
    struct LocalizedTestError: LocalizedError {
        var errorDescription: String? { "Localized failure" }
    }

    @Test("Returns existing connect error")
    func returnsExistingConnectError() {
        let error = ConnectError.simpleError(message: "Already mapped")

        #expect(mapErrorToConnectError(error: error) == error)
    }

    @Test("Maps localized error")
    func mapsLocalizedError() {
        #expect(mapErrorToConnectError(error: LocalizedTestError()) == .simpleError(message: "Localized failure"))
    }

    @Test("Maps cancelled URL error")
    func mapsCancelledURLError() {
        let error = NSError(domain: NSURLErrorDomain, code: -999)

        #expect(mapErrorToConnectError(error: error) == .cancelled)
    }

    @Test("Maps unhandled error")
    func mapsUnhandledError() throws {
        let error = NSError(domain: "Tests", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unknown failure"])
        let mapped = mapErrorToConnectError(error: error)

        guard case .unhandledError(let message, let stackTrace) = mapped else {
            Issue.record("Expected unhandled error")
            return
        }
        #expect(message == "Unknown failure")
        #expect(stackTrace.isEmpty == false)
    }

    @Test("Maps service error detail")
    func mapsServiceErrorDetail() {
        let errorResponse = ErrorResponse(errors: [
            .init(code: "TEST", detail: "Server detail", status: "400", title: "Server title")
        ])

        #expect(mapErrorToConnectError(error: ServiceError.badRequest(errorResponse), parseAppStoreConnectErrors: false) == .simpleError(message: "Server detail"))
    }

    @Test("Maps associated service errors once")
    func mapsAssociatedServiceErrorsOnce() {
        let associated = ErrorResponse.Errors(code: "ASSOCIATED",
                                              detail: "Associated detail",
                                              status: "409",
                                              title: "Associated title")
        let primary = ErrorResponse.Errors(
            code: "PRIMARY",
            detail: "Primary detail",
            meta: .init(associatedErrors: ["items": [associated, associated]]),
            status: "409",
            title: "Primary title")
        let errorResponse = ErrorResponse(errors: [primary])

        #expect(mapErrorToConnectError(error: ServiceError.conflict(errorResponse), parseAppStoreConnectErrors: false) == .errorWithAssociatedErrors(message: "Primary detail", associatedMessages: ["Associated detail"]))
    }
}
