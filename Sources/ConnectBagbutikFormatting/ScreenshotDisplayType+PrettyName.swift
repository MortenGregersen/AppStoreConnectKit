//
//  ScreenshotDisplayType+PrettyName.swift
//  ConnectBagbutikFormatting
//
//  Created by Morten Bjerg Gregersen on 02/10/2025.
//

import Bagbutik_Models

public extension ScreenshotDisplayType {
    var prettyName: String {
        switch self {
        case .appIphone67: #"iPhone 6.7" Display"#
        case .appIphone65: #"iPhone 6.5" Display"#
        case .appIphone61: #"iPhone 6.1" Display"#
        case .appIphone58: #"iPhone 5.8" Display"#
        case .appIphone55: #"iPhone 5.5" Display"#
        case .appIphone47: #"iPhone 4.7" Display"#
        case .appIphone40: #"iPhone 4" Display"#
        case .appIphone35: #"iPhone 3.5" Display"#
        case .appIpadPro3Gen129: #"iPad Pro (3rd Gen) 12.9" Display"#
        case .appIpadPro3Gen11: #"iPad 11" Display"#
        case .appIpadPro129: #"iPad Pro (2nd Gen) 12.9" Display"#
        case .appIpad105: #"iPad 10.5" Display"#
        case .appIpad97: #"iPad 9.7" Display"#
        case .appDesktop: "Mac"
        case .appWatchUltra: "Apple Watch Ultra"
        case .appWatchSeries10: "Apple Watch Series 10"
        case .appWatchSeries7: "Apple Watch Series 7"
        case .appWatchSeries4: "Apple Watch Series 4"
        case .appWatchSeries3: "Apple Watch Series 3"
        case .appAppleTV: "Apple TV"
        case .appAppleVisionPro: "Apple Vision Pro"
        case .iMessageAppIphone67: #"iPhone 6.7" Display"#
        case .iMessageAppIphone65: #"iPhone 6.5" Display"#
        case .iMessageAppIphone61: #"iPhone 6.1" Display"#
        case .iMessageAppIphone58: #"iPhone 5.8" Display"#
        case .iMessageAppIphone55: #"iPhone 5.5" Display"#
        case .iMessageAppIphone47: #"iPhone 4.7" Display"#
        case .iMessageAppIphone40: #"iPhone 4" Display"#
        case .iMessageAppIpadPro3Gen129: #"iPad Pro (3rd Gen) 12.9" Display"#
        case .iMessageAppIpadPro3Gen11: #"iPad 11" Display"#
        case .iMessageAppIpadPro129: #"iPad Pro (2nd Gen) 12.9" Display"#
        case .iMessageAppIpad105: #"iPad 10.5" Display"#
        case .iMessageAppIpad97: #"iPad 9.7" Display"#
        }
    }
}
