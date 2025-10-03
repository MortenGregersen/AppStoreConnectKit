import Bagbutik_Core
@testable import ConnectCore
import Foundation
import Testing

@Suite("ErrorResponse.Errors parsing", .tags(.errors))
struct ParsedErrorResponseErrorsTests {
    @Test("Invalid Entity State")
    func invalidEntityState() {
        let json = #"""
        {
            "id" : "46b75461-5b6b-4f08-9c33-94beedce018b",
            "status" : "409",
            "code" : "STATE_ERROR.ENTITY_STATE_INVALID",
            "title" : "appStoreVersions with id '356bd5b7-219c-4b86-a958-a3ac75064ec7' is not in valid state.",
            "detail" : "This resource cannot be reviewed, please check associated errors to see why."
        }
        """#
        let error = try! JSONDecoder().decode(ErrorResponse.Errors.self, from: json.data(using: .utf8)!)
        #expect(error.parsedDetail == "The action could not be completed, because the item is not in a valid state.")
    }

    @Test("Missing Screenshot")
    func missingScreenshot() {
        let json = #"""
        {
            "id" : "2d8573d3-6c6e-486d-81df-502453e03829",
            "status" : "409",
            "code" : "STATE_ERROR.SCREENSHOT_REQUIRED.APP_IPHONE_55",
            "title" : "App screenshot missing (APP_IPHONE_55).",
            "detail" : "A screenshot with type iphone6Plus is required but was not provided"
        }
        """#
        let error = try! JSONDecoder().decode(ErrorResponse.Errors.self, from: json.data(using: .utf8)!)
        #expect(error.parsedDetail == #"A required screenshot is missing: iPhone 5.5" Display"#)
    }

    @Test("Missing Required Attribute")
    func missingRequiredAttribute() {
        let json = #"""
        {
            "id" : "b91b4d26-e432-4f4a-b3c9-19f1ffbbca8b",
            "status" : "409",
            "code" : "ENTITY_ERROR.ATTRIBUTE.REQUIRED",
            "title" : "The provided entity is missing a required attribute",
            "detail" : "You must provide a value for the attribute 'supportUrl' with this request",
            "source" : {
                "pointer" : "/data/attributes/supportUrl"
            }
        }
        """#
        let error = try! JSONDecoder().decode(ErrorResponse.Errors.self, from: json.data(using: .utf8)!)
        #expect(error.parsedDetail == "A required value is missing: Support URL")
    }

    @Test("Invalid Relationship")
    func invalidRelationship() {
        let json = #"""
        {
            "id" : "0169135a-b9cb-4325-a301-a3b503a78aa6",
            "status" : "409",
            "code" : "ENTITY_ERROR.RELATIONSHIP.INVALID",
            "title" : "The provided entity includes a relationship with an invalid value",
            "detail" : "The appStoreReviewDetail associated with appStoreVersions 77f85282-0a97-4961-bf48-37269d11291f was not found.",
            "source" : {
                "pointer" : "/data/relationships/appStoreReviewDetail"
            }
        }
        """#
        let error = try! JSONDecoder().decode(ErrorResponse.Errors.self, from: json.data(using: .utf8)!)
        #expect(error.parsedDetail == "A associated type is missing or invalid: App Store Review Detail")
    }
}

extension Tag {
    @Tag static var errors: Self
}
