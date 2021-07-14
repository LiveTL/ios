//
//  TranslatedMessage.swift
//  ios
//
//  Created by Mason Phillips on 4/2/21.
//

import Foundation
import SwiftDate

struct TranslatedMessage {
    let author: Author
    let message: String
    let language: String
    
    let timestamp: Date
    let show     : Double
    
    var languageTag: TranslatedLanguageTag {
        return TranslatedLanguageTag(language)!
    }
    
    init?(from message: InjectedMessage) {
        self.author = Author(from: message.author)
        self.timestamp = message.timestamp
        self.show = message.showtime
        
        var m: String? = nil
        var l: String? = nil
        
        if case let .text(s) = message.messages.first {
            for token in tokens {
                guard
                    let begin = s.firstIndex(of: token.start),
                    let end   = s.firstIndex(of: token.end)
                else { continue }
                
                guard begin < end else { continue }
                
                let lang = String(s[begin..<end])
                    .replacingOccurrences(of: "\(token.start)", with: "")
                    .replacingOccurrences(of: "\(token.end)", with: "")
                    .lowercased()
                
                guard TranslatedLanguageTag.allCases.map({ $0.tag }).contains(lang) else { continue }
                let mStart = s.index(after: end)
                m = String(s[mStart..<s.endIndex]).trimmingCharacters(in: [" ", "-", ":"])
                l = lang
                break
            }
            for delim in LangDelims {
                guard let end = s.firstIndex(of: delim) else { continue }
                
                let lang = String(s[s.startIndex..<end])
                    .replacingOccurrences(of: "\(delim)", with: "")
                    .lowercased()
                    .trimmingCharacters(in: [" "])
                
                guard TranslatedLanguageTag.allCases.map({ $0.tag }).contains(lang) else { continue }
                let mStart = s.index(after: end)
                m = String(s[mStart..<s.endIndex]).trimmingCharacters(in: [" ", "-", ":"])
                l = lang
                break
            }
        }
        
        guard let lang = l, let mess = m else { return nil }
        self.message = mess
        self.language = lang
    }
    
    struct Author {
        let name : String
        let types: [String]
        
        init(from author: InjectedMessage.Author) {
            self.name = author.name
            self.types = author.types
        }
    }
}

extension TranslatedMessage: DisplayableMessage {
    var displayAuthor: String { author.name }
    var displayTimestamp: String { timestamp.toRelative(style: RelativeFormatter.twitterStyle()) }
    var displayMessage: [Message] { [.text(message)] }
    
    var sortTimestamp: Date { timestamp }
}
