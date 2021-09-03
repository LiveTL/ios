//
//  DecodableMessage.swift
//  ios
//
//  Created by Mason Phillips on 4/1/21.
//

import Foundation

protocol DisplayableMessage {
    var displayAuthor   : String { get }
    var displayTimestamp: String { get }
    var displayMessage  : [Message] { get }
    var isMod           : Bool { get }
    var isMember        : Bool { get }
    var superchatData   : Superchat? { get }
    
    var sortTimestamp: Date { get }
    var showTimestamp: Double { get }
}

extension DisplayableMessage {
    static func >(l: Self, r: Self) -> Bool {
        return l.sortTimestamp > r.sortTimestamp
    }
    static func <(l: Self, r: Self) -> Bool {
        return l.sortTimestamp < r.sortTimestamp
    }
}

enum Message: Decodable {
    case text(_ str: String)
    case emote(_ url: URL,_ emojiId: String?)

    enum CodingKeys: String, CodingKey {
        case type
        case src, text, emojiId
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let msgType = try container.decode(String.self, forKey: .type)

        if msgType == "emote" {
            let url = try container.decode(URL.self, forKey: .src)
            let emojiId = try container.decode(String?.self, forKey: .emojiId) ?? nil
            self = .emote(url, emojiId)
        } else if msgType == "text" {
            let str = try container.decode(String.self, forKey: .text)
            self = .text(str)
        } else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [CodingKeys.type],
                debugDescription: "Could not find a supported type for the content provided"))
        }
    }
}

extension Message: Equatable {
    
}
