//
//  YouTubeService.swift
//  ios
//
//  Created by Mason Phillips on 4/2/21.
//

import Foundation
import RxCocoa
import RxSwift
import XCDYouTubeKit
import M3U8Kit

struct YouTubeService {
    init() {}
    
    func getYTVideo(_ id: String) -> Single<XCDYouTubeVideo> {
        return Single.create { observer in
            XCDYouTubeClient.default().getVideoWithIdentifier(id) { (video, error) in
                if let error = error { observer(.failure(error)) }
                else if let video = video { observer(.success(video)) }
            }
            
            return Disposables.create {}
        }
    }
    
    func getYTChatURL(_ id: String, videoDuration duration: Double) -> Single<URL> {
        let pattern = """
        continuation":"(\\w+)"
        """

        var chatUrlFinal = "https://www.youtube.com/live_chat"
        
        return Single.create { observer in
            var request = URLRequest(url: URL(string: "https://www.youtube.com/watch?v=\(id)")!)
            request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_6) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/11.1.2 Safari/605.1.15", forHTTPHeaderField: "User-Agent")
            let task = URLSession.shared.dataTask(with: request) { data, _, _ in
                if let data = data, let html = String(data: data, encoding: .utf8) {
                    if let token = html.groups(for: pattern).first?.last, duration > 0 {
                        // is replay stream
                        chatUrlFinal.append("_replay?v=\(id)&continuation=\(token)&embed_domain=www.livetl.app&app=desktop")
                    } else {
                        chatUrlFinal.append("?v=\(id)&embed_domain=www.livetl.app&app=desktop")
                    }
                    
                    observer(.success(URL(string: chatUrlFinal)!))
                } else {
                    observer(.failure(YouTubeError.failedToRetrieveChatUrl))
                }
            }
            task.resume()
            
            return Disposables.create {
                task.cancel()
            }
        }
    }
    
    enum YouTubeError: Error {
        case failedToRetrieveChatUrl
    }
}

enum YouTubeResolution: String, CustomStringConvertible, CaseIterable {
    var description: String {
        switch self {
        case .hd2160p: return "2160p"
        case .hd1440p: return "1440p"
        case .hd1080p: return "1080p"
        case .hd720p : return "720p"
        case .sd480p : return "480p"
        case .sd360p : return "360p"
        case .sd240p : return "240p"
        case .auto   : return "Auto"
        }
    }
    
    init(_ res: MediaResoulution) {
        switch res {
        case MediaResoulution(width: 3840, height: 2160): self = .hd2160p
        case MediaResoulution(width: 2560, height: 1440): self = .hd1440p
        case MediaResoulution(width: 1920, height: 1080): self = .hd1080p
        case MediaResoulution(width: 1280, height: 720) : self = .hd720p
        case MediaResoulution(width: 854, height: 480)  : self = .sd480p
        case MediaResoulution(width: 640, height: 360)  : self = .sd360p
        case MediaResoulution(width: 426, height: 240)  : self = .sd240p
        default:
            self = .auto
        }
    }
    
    var mediaResolution: MediaResoulution {
        switch self {
        case .auto:
            return MediaResoulution()
        case .hd2160p:
            return MediaResoulution(width: 3840, height: 2160)
        case .hd1440p:
            return MediaResoulution(width: 2560, height: 1440)
        case .hd1080p:
            return MediaResoulution(width: 1920, height: 1080)
        case .hd720p:
            return MediaResoulution(width: 1280, height: 720)
        case .sd480p:
            return MediaResoulution(width: 854, height: 480)
        case .sd360p:
            return MediaResoulution(width: 640, height: 360)
        case .sd240p:
            return MediaResoulution(width: 426, height: 240)
        }
    }
    
    case auto, hd2160p, hd1440p, hd1080p, hd720p, sd480p, sd360p, sd240p
}

extension String {
    func groups(for regexPattern: String) -> [[String]] {
        do {
            let text = self
            let regex = try NSRegularExpression(pattern: regexPattern)
            let matches = regex.matches(in: text,
                                    range: NSRange(text.startIndex..., in: text))
            return matches.map { match in
                return (0..<match.numberOfRanges).map {
                    let rangeBounds = match.range(at: $0)
                    guard let range = Range(rangeBounds, in: text) else {
                        return ""
                    }
                    return String(text[range])
                }
            }
        } catch let error {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }

}
