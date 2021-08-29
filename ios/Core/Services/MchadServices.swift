//
//  MchadServices.swift
//  ios
//
//  Created by Andrew Glaze on 8/24/21.
//

import Foundation
import RxCocoa
import RxSwift

struct MchadServices {
    init() {}
    
    func getMchadRoom(id: String, duration: Double) -> Single<[MchadRoom]> {
        return Single.create { observer in
            let request: URLRequest
            if duration > 0 {
                // is replay
                request = URLRequest(url: URL(string: "https://repo.mchatx.org/Archive?link=YT_\(id)")!)
            } else {
                request = URLRequest(url: URL(string: "https://repo.mchatx.org/Room?link=YT_\(id)")!)
            }
            let task = URLSession.shared.dataTask(with: request) { data, _, error in
                if let data = data, let room = String(data: data, encoding: .utf8) {
                    do {
                        //print(room)
                        let decoder = JSONDecoder()
                        let json = try decoder.decode([MchadRoom].self, from: data)
                        observer(.success(json))
                    } catch {
                        print(error)
                        //observer(.failure(error))
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
    
    func getMchadArchiveTls(_ id: String, room: MchadRoom) -> Single<[TranslatedMessage?]> {
        Single.create { observer in
            let bag = DisposeBag()
            let meta = BehaviorRelay<HoloDexResponse?>(value: nil)
            let start = BehaviorRelay<Date?>(value: nil)
            
            var request = URLRequest(url: URL(string: "https://repo.mchatx.org/Archive")!)
            request.httpMethod = "POST"
            request.addValue("application/json, text/plain, */*", forHTTPHeaderField: "Accept")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let jsonObject = NSMutableDictionary()
            jsonObject.setValue(room.Link, forKey: "link")
            let jsonData: NSData
            do {
                jsonData = try JSONSerialization.data(withJSONObject: jsonObject, options: JSONSerialization.WritingOptions()) as NSData
                request.httpBody = jsonData as Data?
            } catch  {
                print(error)
            }
            
            let task = URLSession.shared.dataTask(with: request) { data, _, error in
                if let data = data {
                    do {
                        let decoder = JSONDecoder()
                        let json = try decoder.decode([MchadScript].self, from: data)
                        
                        if let startTime = json.first(where: { $0.Stext == "--- Stream Starts ---"})?.Stime {
                            let messages = json.map { TranslatedMessage(from: $0, room: room) }
                            
                            observer(.success(messages))
                        } else if let startTime = json.first?.Stime {
                            
                        } else {
                            let startTime = Date.distantPast
                        }
                        //observer(.success(json))
                    } catch {
                        //observer(.failure(error))
                        print(error)
                    }
                } else if let error = error {
                    print(error)
                    //observer(.failure(error))
                }
            }
            task.resume()
            
            return Disposables.create {
                task.cancel()
            }
        }
    }
}
