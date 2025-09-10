//
//  Language.swift
//  Interactive AI
//
//  Created by Irham Sahbana on 06/09/25.
//

import Foundation

enum Language: String, CaseIterable {
    case english = "en-US"
    case korean = "ko-KR"

    var displayName: String {
        switch self {
        case .english:
            return "English"
        case .korean:
            return "Korean"
        }
    }

    var nativeName: String {
        switch self {
        case .english:
            return "English"
        case .korean:
            return "한국어"
        }
    }

    var flag: String {
        switch self {
        case .english:
            return "🇺🇸"
        case .korean:
            return "🇰🇷"
        }
    }

    var localeIdentifier: String {
        return rawValue
    }
}
