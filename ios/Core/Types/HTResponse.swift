//
//  HTResponse.swift
//  ios
//
//  Created by Mason Phillips on 3/25/21.
//

import Foundation
import RxDataSources

struct HTResponse: Decodable, Equatable {
    let live    : [Streamer]
    let upcoming: [Streamer]
    let ended   : [Streamer]
    
    struct Streamer: Decodable, Identifiable, Equatable {
        let id: Int
        let yt_video_key: String?
        let bb_video_id: String?
        let title: String
        let thumbnail: URL?
        let status: String
        let live_schedule: Date
        let live_start: Date?
        let live_end: Date?
        let live_viewers: Int?
        let channel: Channel
        
        var videoId: String {
            return yt_video_key ?? bb_video_id ?? "VID_ID_ERR"
        }
        
        enum LiveState: String, Decodable {
            case live, upcoming, ended
        }
        
        struct Channel: Decodable {
            let id: Int
            let yt_channel_id: String?
            let bb_space_id: String?
            let name: String
            let photo: URL
            let published_at: Date
            let twitter_link: String
            let view_count: Int
            let subscriber_count: Int
            let video_count: Int
        }
        
        static func ==(l: Streamer, r: Streamer) -> Bool {
            return l.id == r.id
        }
    }
    
    static func ==(l: HTResponse, r: HTResponse) -> Bool {
        return
            l.live.elementsEqual(r.live) &&
            l.upcoming.elementsEqual(r.upcoming) &&
            l.ended.elementsEqual(r.ended)
    }
    
    func sortedDict() -> Dictionary<Streamer.LiveState, Array<Streamer>> {
        return [
            .live    : live.sorted { $0.live_schedule < $1.live_schedule },
            .upcoming: upcoming.sorted { $0.live_schedule > $1.live_schedule },
            .ended   : ended.sorted { $0.live_schedule > $1.live_schedule }
        ]
    }
    
    static func `default`() -> Self {
        return Self.init(live: [], upcoming: [], ended: [])
    }
}
