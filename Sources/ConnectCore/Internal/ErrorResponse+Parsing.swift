//
//  ErrorResponse+Parsing.swift
//  ConnectCore
//
//  Created by Morten Bjerg Gregersen on 02/10/2025.
//

import Bagbutik_Core
import Bagbutik_Models
import ConnectBagbutikFormatting
import Foundation

extension ErrorResponse.Errors {
    var parsedDetail: String {
        if code.hasPrefix("STATE_ERROR.ENTITY_STATE_INVALID") {
            return "The action could not be completed, because the item is not in a valid state."
        } else if code.hasPrefix("STATE_ERROR.SCREENSHOT_REQUIRED."),
                  let displayType = ScreenshotDisplayType(rawValue: String(code.split(separator: ".")[2])) {
            return "A required screenshot is missing: \(displayType.prettyName)"
        } else if code.hasPrefix("ENTITY_ERROR.ATTRIBUTE.REQUIRED"),
                  case .jsonPointer(let jsonPointer) = source,
                  jsonPointer.pointer.hasPrefix("/data/attributes/") {
            let attributeName = String(jsonPointer.pointer.suffix(from: .init(utf16Offset: 17, in: jsonPointer.pointer)))
            return "A required value is missing: \(attributeName.camelCaseToTitleCase.magicWordsFixed)"
        } else if code.hasPrefix("ENTITY_ERROR.RELATIONSHIP.INVALID"),
                  case .jsonPointer(let jsonPointer) = source,
                  jsonPointer.pointer.hasPrefix("/data/relationships/") {
            let relationshipName = String(jsonPointer.pointer.suffix(from: .init(utf16Offset: 20, in: jsonPointer.pointer)))
            return "A associated type is missing or invalid: \(relationshipName.camelCaseToTitleCase.magicWordsFixed)"
        }
        return detail ?? title
    }
}
