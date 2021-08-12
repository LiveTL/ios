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
    let languages: [String]
    
    let timestamp: Date
    let show     : Double
    let superchat: Superchat?
    
    init?(from message: InjectedMessage) {
        self.author = Author(from: message.author)
        self.timestamp = message.timestamp
        self.show = message.showtime
        self.superchat = message.superchat
        
        var m: String? = nil
        var l: [String]? = nil
        
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
                var finalLang: [String] = []
                
                do {
                    for splitLang in try lang.split(usingRegex: "\\W+") {
                        guard TranslatedLanguageTag.allCases.map({ $0.tag }).contains(splitLang) || TranslatedLanguageTag.allCases.map({ $0.description.lowercased().hasPrefix(splitLang) }).contains(Bool.init(true)) || TranslatedLanguageTag.allCases.map({ $0.tag.lowercased().hasPrefix(splitLang) }).contains(Bool.init(true)) else { continue }
                        finalLang.append(splitLang)
                    }
                } catch {
                    print("Whoops")
                }
                
                
                
                let mStart = s.index(after: end)
                m = String(s[mStart..<s.endIndex]).trimmingCharacters(in: [" ", "-", ":"])
                l = finalLang
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
                l = [lang]
                break
            }
        }
        
        guard let lang = l, let mess = m else { return nil }
        self.message = mess
        self.languages = lang
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
}

extension String {
    func split(usingRegex pattern: String) throws -> [String] {
        //### Crashes when you pass invalid `pattern`
        let regex = try NSRegularExpression(pattern: pattern)
        let matches = regex.matches(in: self, range: NSRange(0..<utf16.count))
        let ranges = try [startIndex..<startIndex] + matches.map{
            guard let test = Range($0.range, in: self) else { throw TypeError.badType }
            return test
        } + [endIndex..<endIndex]
        return (0...matches.count).map {String(self[ranges[$0].upperBound..<ranges[$0+1].lowerBound])}
    }
}

enum TypeError: Error {
    case badType
}
