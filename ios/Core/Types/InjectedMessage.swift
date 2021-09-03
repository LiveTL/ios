//
//  InjectedMessage.swift
//  ios
//
//  Created by Mason Phillips on 4/2/21.
//

import Foundation
import SwiftDate

struct MessageChunk: Decodable {
    let type: String
    let messages: [InjectedMessage]
    let isReplay: Bool
}

struct InjectedMessage: Decodable {
    let author: Author
    let messages: [Message]
    let showtime: Double
    let timestamp: Date
    let superchat: Superchat?

    struct Author: Decodable {
        let id: String
        let name: String
        let types: [String]
    }
}

extension InjectedMessage: DisplayableMessage {
    var displayAuthor: String { author.name }
    var displayTimestamp: String { timestamp.toRelative(style: RelativeFormatter.twitterStyle()) }
    var displayMessage: [Message] { messages }
    var isMod: Bool { author.types.contains("moderator") }
    var isMember: Bool {
        if author.types.contains("new member") {
            return true
        } else {
            for type in author.types {
                if type.hasPrefix("member") {
                    return true
                }
            }
        }
        return false
    }
    var superchatData: Superchat? { superchat }

    var sortTimestamp: Date { timestamp }
    var showTimestamp: Date { Date(timeIntervalSinceNow: showtime/1000) }
}
