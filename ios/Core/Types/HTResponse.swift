//
//  HTResponse.swift
//  ios
//
//  Created by Mason Phillips on 3/25/21.
//

import Foundation
import RxDataSources

struct HTResponse: Decodable, Equatable {
    let items    : [Streamer]
    //let upcoming: [Streamer]
    //let ended   : [Streamer]
    
    struct Streamer: Decodable, Identifiable, Equatable {
        let id: String
        let title: String
        let type: String
        let published_at: Date
        let available_at: Date?
        let status: LiveState
        let start_scheduled: Date
        let start_actual: Date?
        let live_viewers: Int?
        let channel: Channel
        
        enum LiveState: String, Decodable {
            case new, upcoming, live, past, missing
        }
        
        struct Channel: Decodable {
            let id: String
            let name: String
            let type: String
            let photo: URL
            let english_name: String
        }
        
        static func ==(l: Streamer, r: Streamer) -> Bool {
            return l.id == r.id
        }
    }
    
    static func ==(l: HTResponse, r: HTResponse) -> Bool {
        return
            l.items.elementsEqual(r.items) //&&
            //l.upcoming.elementsEqual(r.upcoming) &&
            //l.ended.elementsEqual(r.ended)
    }
    
    func sortedDict() -> Dictionary<Streamer.LiveState, Array<Streamer>> {
        return [
            .live    : items.sorted { $0.start_scheduled < $1.start_scheduled },
            //.upcoming: upcoming.sorted { $0.live_schedule > $1.live_schedule },
            //.ended   : ended.sorted { $0.live_schedule > $1.live_schedule }
        ]
    }
    
    static func `default`() -> Self {
        return Self.init(items: [])
    }
}
