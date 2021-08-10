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


let LangDelims: [Character] = ["-", ":", "-"]

enum TranslatedLanguageTag: String, CustomStringConvertible, CaseIterable {
    case en, jp, es, id, kr, zh, ru, fr
    case dev
    
    var description: String {
        switch self {
        case .en: return Bundle.main.localizedString(forKey: "English", value: "English", table: "Localizeable")
        case .jp: return Bundle.main.localizedString(forKey: "Japanese", value: "Japanese", table: "Localizeable")
        case .es: return Bundle.main.localizedString(forKey: "Spanish", value: "Spanish", table: "Localizeable")
        case .id: return Bundle.main.localizedString(forKey: "Indonesian", value: "Indonesian", table: "Localizeable")
        case .kr: return Bundle.main.localizedString(forKey: "Korean", value: "Korean", table: "Localizeable")
        case .zh: return Bundle.main.localizedString(forKey: "Chinese", value: "Chinese", table: "Localizeable")
        case .ru: return Bundle.main.localizedString(forKey: "Russian", value: "Russian", table: "Localizeable")
        case .fr: return Bundle.main.localizedString(forKey: "French", value: "French", table: "Localizeable")
            
        case .dev: return Bundle.main.localizedString(forKey: "Developer Tags", value: "Developer Tags", table: "Localizeable")
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
