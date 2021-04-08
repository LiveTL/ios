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
    let author   : Author
    let messages : [Message]
    let showtime : Double
    let timestamp: Date
    
    struct Author: Decodable {
        let id: String
        let name: String
        let types: [String]
    }
}

extension InjectedMessage: DisplayableMessage {
    var displayAuthor   : String { author.name }
    var displayTimestamp: String { timestamp.toRelative(style: RelativeFormatter.twitterStyle()) }
    var displayMessage  : [Message] { messages }
    
    var sortTimestamp: Date { timestamp }
}
