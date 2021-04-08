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
                    print(duration)
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
