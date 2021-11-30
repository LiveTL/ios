//
//  StreamModel.swift
//  ios
//
//  Created by Mason Phillips on 4/1/21.
//

import FontAwesome_swift
import Foundation
import NotificationBannerSwift
import RxCocoa
import RxFlow
import RxSwift
import WebKit
import XCDYouTubeKit

typealias ReplayEvent = (current: Double, id: String)

protocol StreamModelType {
    var input: StreamModelInput { get }
    var output: StreamModelOutput { get }
}

protocol StreamModelInput {
    var chatControl: BehaviorRelay<ChatControlType> { get }
    var timeControl: BehaviorRelay<ReplayEvent> { get }
    
    func load(_ id: String)
    func loadPreviewChat(_ id: String, duration: Double)
    func getMetadata(_ id: String)
}

protocol StreamModelOutput {
    var errorRelay: BehaviorRelay<Error?> { get }

    var loadingDriver: Driver<Bool> { get }
    var emptyDriver: Driver<Bool> { get }
    var chatDriver: Driver<[DisplayableMessage]> { get }
    var captionDriver: Driver<[DisplayableMessage]> { get }
    var videoDriver: Driver<XCDYouTubeVideo?> { get }
    var metaDriver: Driver<HoloDexResponse?> { get }
}

class StreamModel: BaseModel {
    private let chatView = WKWebView(frame: .zero)
    
    private let playerRelay = BehaviorRelay<XCDYouTubeVideo?>(value: nil)
    
    private let controlRelay = BehaviorRelay<ChatControlType>(value: .allChat)
    
    private let chatRelay = BehaviorRelay<[DisplayableMessage]>(value: [])
    private let liveRelay = BehaviorRelay<[DisplayableMessage]>(value: [])
    private let translatedRelay = BehaviorRelay<[DisplayableMessage]>(value: [])
    
    private let loadingRelay = BehaviorRelay<Bool>(value: true)
    private let emptyRelay = BehaviorRelay<Bool>(value: true)
    
    private let chatURLRelay = BehaviorRelay<URL?>(value: nil)
    private let mchadRoomRelay = BehaviorRelay<MchadRoom?>(value: nil)
    private let mchadScriptRelay = BehaviorRelay<([TranslatedMessage], MchadRoom?)?>(value: ([], nil))
    private let metadataRelay = BehaviorRelay<HoloDexResponse?>(value: nil)
    
    private let replayRelay = BehaviorRelay<Bool>(value: false)
    private let replayEventRelay = BehaviorRelay<ReplayEvent>(value: (0.0, ""))
    
    override init(_ services: AppServices) {
        super.init(services)
        
        chatView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_6) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/11.1.2 Safari/605.1.15"
        
        Observable.combineLatest(replayRelay, replayEventRelay).filter { $0.0 }
            .compactMap { $0.1 }
            .subscribe(onNext: { time, id in
                let js = """
                    window.postMessage({ "yt-player-video-progress": \(time), video: "\(id)"}, '*');
                """
                
                DispatchQueue.main.async {
                    self.chatView.evaluateJavaScript(js, completionHandler: nil)
                }
            }).disposed(by: bag)

        replayEventRelay
            .compactMap { $0.current }
            .sample(Observable<Int>.interval(.milliseconds(500), scheduler: MainScheduler.instance), defaultValue: 0.0)
            .scan((0.0, false)) { last, current in
                (current, last.0 > current)
            }
            .filter { $0.1 }
            .subscribe(onNext: { _, _ in
                self.liveRelay.accept([])
                self.translatedRelay.accept([])
                self.chatRelay.accept([])
            }).disposed(by: bag)
        Observable.combineLatest(controlRelay, liveRelay, translatedRelay).map { control, live, translated in
            control == .allChat ? live : translated
        }
        .map { $0.sorted { $0.sortTimestamp > $1.sortTimestamp } }
        .bind(to: chatRelay)
        .disposed(by: bag)
        
        playerRelay.compactMap { $0 }
            .map { (id: $0.identifier, duration: $0.duration) }
            .subscribe(onNext: loadChat)
            .disposed(by: bag)
        
        playerRelay.compactMap { $0 }
            .map { (id: $0.identifier, duration: $0.duration) }
            .subscribe(onNext: loadMchadRooms)
            .disposed(by: bag)
        
        chatView.navigationDelegate = self
        chatURLRelay.compactMap { $0 }
            .map { URLRequest(url: $0) }
            .subscribe(onNext: { request in DispatchQueue.main.async { self.chatView.load(request) }})
            .disposed(by: bag)
        chatURLRelay.compactMap { $0 }
            .map { $0.absoluteString.contains("live_chat_replay") }
            .bind(to: replayRelay)
            .disposed(by: bag)
        mchadRoomRelay.compactMap { $0 }
            .subscribe(onNext: { room in self.loadMchadArchiveScript(room) })
            .disposed(by: bag)
        mchadScriptRelay.compactMap { $0 }
            .subscribe(onNext: { script, room in
                self.appendMchadScriptTls(script, room: room)
            })
            .disposed(by: bag)
        
        do {
            let path = Bundle.main.path(forResource: "WindowInjector", ofType: "js") ?? ""
            let js = try String(contentsOfFile: path, encoding: .utf8)
            let script = WKUserScript(source: js, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
            
            chatView.configuration.userContentController.addUserScript(script)
            chatView.configuration.userContentController.add(self, name: "ios_messageReceive")
        } catch {
            print(error)
        }
    }

    private func loadVideoPlayer(_ id: String) {
        let request = services.youtube.getYTVideo(id)
            .asObservable()
            .materialize()
            
        request.map { $0.element }
            .bind(to: playerRelay)
            .disposed(by: bag)
        request.map { $0.error }
            .map { error -> Error? in
                guard let error = error as NSError? else { return nil }
                if error.code == -2, error.localizedDescription.isEmpty {
                    return NSError(domain: XCDYouTubeVideoErrorDomain, code: -2, userInfo: [
                        NSLocalizedDescriptionKey: "This stream either has not started yet, is private, is member-only, or is not playable for some other reason."
                    ])
                }
                return error
            }
            .bind(to: errorRelay)
            .disposed(by: bag)
    }
    
    func getVideoMeta(_ id: String) {
        let meta = services.holodex.getMetadata(id)
            .asObservable()
            .materialize()
        
        meta.map { $0.element }
            .bind(to: metadataRelay)
            .disposed(by: bag)
    }
    
    private func loadMchadRooms(_ id: String, duration: Double) {
        let request = services.mchad.getMchadRoom(id: id, duration: duration)
            .asObservable()
            .materialize()
        
        request.map { $0.element }
            .bind(to: mchadRoomRelay)
            .disposed(by: bag)
        request.map { $0.error }
            .bind(to: errorRelay)
            .disposed(by: bag)
    }
    
    private func loadMchadArchiveScript(_ room: MchadRoom) {
        let request = services.mchad.getMchadArchiveTls(room)
            .asObservable()
            .materialize()
        
        request.map { $0.element }
            .bind(to: mchadScriptRelay)
            .disposed(by: bag)
        request.map { $0.error }
            .subscribe(onError: { error in print(error) })
            .disposed(by: bag)
    }
    
    private func appendMchadScriptTls(_ script: [TranslatedMessage], room: MchadRoom?) {
        var mutableScript = script
        var mchadOffset: Double = 0.0
        
        for displayableMessage in script {
            if displayableMessage.message.first == Message.text("--- Stream Starts ---") {
                mchadOffset = displayableMessage.showTimestamp
                break
            }
        }
        
        replayEventRelay.compactMap { $0.current }
            .sample(Observable<Int>.interval(.milliseconds(500), scheduler: MainScheduler.instance), defaultValue: 0.0)
            .subscribe(onNext: { time in
                var currentRelay = self.translatedRelay.value
                let tmpScript = mutableScript.filter { $0.showTimestamp - mchadOffset <= time * 1000 }
                mutableScript.removeFirst(tmpScript.endIndex)
                for message in tmpScript {
                    for lang in message.languages {
                        if self.services.settings.languages.map({ $0.tag }).contains(lang) ||
                            self.services.settings.languages.map({ $0.description.lowercased().hasPrefix(lang) }).contains(Bool(true)) ||
                            self.services.settings.languages.map({ $0.tag.lowercased().hasPrefix(lang) }).contains(Bool(true)),
                           !self.services.settings.neverUsers.contains(message.displayAuthor)
                        {
                            var mutableMessage = message
                            mutableMessage.timestamp = Date()
                            currentRelay.append(mutableMessage)
                        }
                    }
                }
               
                if !tmpScript.isEmpty {
                    self.translatedRelay.accept(currentRelay)
                }
            })
            .disposed(by: bag)
    }

    private func loadChat(_ id: String, duration: Double) {
        let request = services.youtube.getYTChatURL(id, videoDuration: duration)
            .asObservable()
            .materialize()
           
        request.map { $0.element }
            .bind(to: chatURLRelay)
            .disposed(by: bag)
        request.map { $0.error }
            .bind(to: errorRelay)
            .disposed(by: bag)
    }
}

extension StreamModel: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? String, let data = body.data(using: .utf8) else { return }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .millisecondsSince1970
            let items = try decoder.decode(MessageChunk.self, from: data)
            
            var full = liveRelay.value
            full.append(contentsOf: items.messages)
            liveRelay.accept(full)
            
            var translated = translatedRelay.value
            let mapped = items.messages.compactMap(translate(_:))
            translated.append(contentsOf: mapped)
            translatedRelay.accept(translated)
            
        } catch {
            print(error)
        }
    }
    
    func translate(_ message: InjectedMessage) -> DisplayableMessage? {
        if services.settings.spotlightUser != nil {
            if services.settings.spotlightUser == message.displayAuthor {
                return message
            } else {
                return nil
            }
        }
        
        if let translated = TranslatedMessage(from: message) {
            for lang in translated.languages {
                if lang == "" { continue }
                if services.settings.languages.map({ $0.tag }).contains(lang) ||
                    services.settings.languages.map({ $0.description.lowercased().hasPrefix(lang) }).contains(Bool(true)) ||
                    services.settings.languages.map({ $0.tag.lowercased().hasPrefix(lang) }).contains(Bool(true)),
                    !services.settings.neverUsers.contains(translated.displayAuthor)
                {
                    return translated
                }
            }
        }
        
        if services.settings.alwaysUsers.contains(message.displayAuthor) {
            return message
        }
        
        if services.settings.modMessages, message.author.types.map({ $0.lowercased() }).contains("mod") {
            return message
        }
        
        return nil
    }
}

extension StreamModel: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        loadingRelay.accept(true)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        loadingRelay.accept(false)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        errorRelay.accept(error)
    }
}

extension StreamModel: UITableViewDelegate {
    func handleFavoriteUser(at index: IndexPath) {
        let value = chatRelay.value[index.row]
        let author = value.displayAuthor
        services.settings.alwaysUsers.append(author)
        
        let leftView = UIImageView(image: UIImage.fontAwesomeIcon(code: "fa-star", style: .solid, textColor: .white, size: CGSize(width: 400, height: 400)))
        let banner = FloatingNotificationBanner(title: Bundle.main.localizedString(forKey: "Added", value: "Added", table: "Localizeable"), subtitle: String(format: NSLocalizedString("Translator %@ has been added to the translator filter.", tableName: "Localizeable", comment: "a comment"), author), leftView: leftView, style: .success)
        banner.haptic = BannerHaptic.light
        banner.show(cornerRadius: 10, shadowBlurRadius: 15)
    }

    func handleMuteUser(at index: IndexPath) {
        let value = chatRelay.value[index.row]
        let author = value.displayAuthor
        services.settings.neverUsers.append(author)
        
        let leftView = UIImageView(image: UIImage.fontAwesomeIcon(code: "fa-comment-slash", style: .solid, textColor: .white, size: CGSize(width: 400, height: 400)))
        let banner = FloatingNotificationBanner(title: Bundle.main.localizedString(forKey: "Blocked", value: "Blocked", table: "Localizeable"), subtitle: String(format: NSLocalizedString("Translator %@ has been blocked.", tableName: "Localizeable", comment: "a comment"), author), leftView: leftView, style: .danger)
        banner.haptic = BannerHaptic.light
        banner.show(cornerRadius: 10, shadowBlurRadius: 15)
    }

    func handleSpotlightUser(at index: IndexPath) {
        let value = chatRelay.value[index.row]
        let author = value.displayAuthor
        services.settings.spotlightUser = author
        
        let leftView = UIImageView(image: UIImage.fontAwesomeIcon(code: "fa-thumbtack", style: .solid, textColor: .white, size: CGSize(width: 400, height: 400)))
        let banner = FloatingNotificationBanner(title: Bundle.main.localizedString(forKey: "Pinned", value: "Pinned", table: "Localizeable"), subtitle: String(format: NSLocalizedString("Translator %@ has been pinned. You will only recieve translations from them until you close this stream.", tableName: "Localizeable", comment: "a comment"), author), leftView: leftView, style: .info)
        banner.haptic = BannerHaptic.light
        banner.show(cornerRadius: 10, shadowBlurRadius: 15)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: "FontAwesome5Pro-Solid", size: 20)!,
            .foregroundColor: UIColor.white
        ]
        
        let favorite = UIContextualAction(style: .normal, title: "") { [indexPath] _, _, completion in
            self.handleFavoriteUser(at: indexPath)
            completion(true)
        }
        favorite.image = "\u{f005}".image(withAttributes: attrs, size: CGSize(width: 25, height: 20))
        favorite.backgroundColor = .systemGreen
        
        let mute = UIContextualAction(style: .normal, title: "") { [indexPath] _, _, completion in
            self.handleMuteUser(at: indexPath)
            completion(true)
        }
        mute.image = "\u{f4b3}".image(withAttributes: attrs, size: CGSize(width: 25, height: 20))
        mute.backgroundColor = .systemRed
        
        let spotlight = UIContextualAction(style: .normal, title: "") { [indexPath] _, _, completion in
            self.handleSpotlightUser(at: indexPath)
            completion(true)
        }
        spotlight.image = UIImage.fontAwesomeIcon(code: "fa-thumbtack", style: .solid, textColor: .white, size: CGSize(width: 25, height: 20))
        spotlight.backgroundColor = .systemBlue
        
        return UISwipeActionsConfiguration(actions: [favorite, spotlight, mute])
    }
}

extension StreamModel: StreamModelType {
    var input: StreamModelInput { self }
    var output: StreamModelOutput { self }
}

extension StreamModel: StreamModelInput {
    var timeControl: BehaviorRelay<ReplayEvent> { replayEventRelay }
    var chatControl: BehaviorRelay<ChatControlType> { controlRelay }
    
    func load(_ id: String) {
        loadVideoPlayer(id)
    }

    func loadPreviewChat(_ id: String, duration: Double) {
        loadChat(id, duration: duration)
    }

    func getMetadata(_ id: String) {
        getVideoMeta(id)
    }
}

extension StreamModel: StreamModelOutput {
    var loadingDriver: Driver<Bool> { loadingRelay.asDriver() }
    var emptyDriver: Driver<Bool> { chatRelay.map { $0.isEmpty }.asDriver(onErrorJustReturn: true) }
    var chatDriver: Driver<[DisplayableMessage]> { chatRelay.asDriver() }
    var captionDriver: Driver<[DisplayableMessage]> { translatedRelay.asDriver() }
    var videoDriver: Driver<XCDYouTubeVideo?> { playerRelay.asDriver() }
    var metaDriver: Driver<HoloDexResponse?> { metadataRelay.asDriver() }
}

extension String {
    func image(withAttributes attributes: [NSAttributedString.Key: Any]? = nil, size: CGSize? = nil) -> UIImage {
        let size = size ?? (self as NSString).size(withAttributes: attributes)
        return UIGraphicsImageRenderer(size: size).image { _ in
            (self as NSString).draw(in: CGRect(origin: .zero, size: size), withAttributes: attributes)
        }
    }
}
