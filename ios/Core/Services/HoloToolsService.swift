//
//  HoloToolsService.swift
//  ios
//
//  Created by Mason Phillips on 3/28/21.
//

import Foundation
import RxCocoa
import RxSwift

struct HoloToolsService {
    init() {}
    
    func streamers() -> Single<HTResponse> {
        return Single.create { observer in
            let url = URL(string: "https://jetrico.sfo2.digitaloceanspaces.com/hololive/youtube.json")!
            let task = URLSession.shared.dataTask(with: url) { response, _, error in
                if let response = response {
                    do {
                        let decoder = JSONDecoder()
                        decoder.dateDecodingStrategy = .iso8601WithMilli
                        let json = try decoder.decode(HTResponse.self, from: response)
                        observer(.success(json))
                    } catch {
                        observer(.failure(error))
                    }
                } else if let error = error {
                    observer(.failure(error))
                }
            }
            
            task.resume()
            
            return Disposables.create {
                task.cancel()
            }
        }
    }
}

extension JSONDecoder.DateDecodingStrategy {
    static var iso8601WithMilli: Self {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)

        return .custom({ (decoder) -> Date in
            let container = try decoder.singleValueContainer()
            let dateStr = try container.decode(String.self)

            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
            if let date = formatter.date(from: dateStr) {
                return date
            }
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXXXX"
            if let date = formatter.date(from: dateStr) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "No valid date format")
        })
    }
}
