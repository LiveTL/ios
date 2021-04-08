//
//  Language.swift
//  ios
//
//  Created by Mason Phillips on 4/2/21.
//

import Foundation

typealias LangToken = (start: Character, end: Character)
let tokens: [LangToken] = [
    (start: "[", end: "]"),
    (start: "{", end: "}"),
    (start: "(", end: ")"),
    (start: "|", end: "|"),
    (start: "<", end: ">"),
    (start: "【", end: "】"),
    (start: "「", end: "」"),
    (start: "『", end: "』"),
    (start: "〚", end: "〛"),
    (start: "（", end: "）"),
    (start: "〈", end: "〉"),
    (start: "⁽", end: "₎")
]

enum TranslatedLanguageTag: String, CustomStringConvertible, CaseIterable {
    case en, jp, es, id, kr, zh, ru, fr
    case dev
    
    var description: String {
        switch self {
        case .en: return "English"
        case .jp: return "Japanese"
        case .es: return "Spanish"
        case .id: return "Indonesian"
        case .kr: return "Korean"
        case .zh: return "Chinese"
        case .ru: return "Russian"
        case .fr: return "French"
            
        case .dev: return "Developer Tags"
        }
    }
    
    var tag: String {
        switch self {
        case .en: return "en"
        case .jp: return "jp"
        case .es: return "es"
        case .id: return "id"
        case .kr: return "kr"
        case .zh: return "zh"
        case .ru: return "ru"
        case .fr: return "fr"

        case .dev: return "dev"
        }
    }
    
    init?(_ from: String) {
        switch from {
        case "English", "en"   : self = .en
        case "Japanese", "jp"  : self = .jp
        case "Spanish", "es"   : self = .es
        case "Indonesian", "id": self = .id
        case "Korean", "kr"    : self = .kr
        case "Chinese", "zh"   : self = .zh
        case "Russian", "ru"   : self = .ru
        case "French", "fr"    : self = .fr
            
        case "Developer Tags", "dev": self = .dev
            
        default: return nil
        }
    }
}
