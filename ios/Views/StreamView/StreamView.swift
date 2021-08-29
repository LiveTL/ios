//
//  StreamView.swift
//  ios
//
//  Created by Mason Phillips on 3/25/21.
//

import AVKit
import M3U8Kit
import Neon
import RxCocoa
import RxFlow
import RxSwift
import SCLAlertView
import UIKit

class StreamView: BaseController {
    var videoPlayer = AVPlayerViewController()
    let videoView = UIView(frame: .zero)
    var player: AVPlayer? = AVPlayer(playerItem: nil)
    var videoID: String = ""
    
    var waitRoomView = UIImageView()
    var waitRoomTextView = UIView()
    var waitRoomTime = Int()
    var waitRoom = false
    let waitTimeText = UILabel()
    let waitTimeScheduled = UILabel()
    
    let chatTable = ChatTable(frame: .zero, style: .plain)
    let chatControl: UISegmentedControl
    var caption = UILabel()
    let captionFontSize: CGFloat = 17.0
    
    let model: StreamModelType
    let settingsService: SettingsService
    let sharedAudio = AVAudioSession.sharedInstance()
    
    var leftButton: UIBarButtonItem {
        let b = UIBarButtonItem(title: "times", style: .plain, target: self, action: #selector(closeStream))
        b.setTitleTextAttributes([.font: UIFont(name: "FontAwesome5Pro-Solid", size: 20)!], for: .normal)
        b.setTitleTextAttributes([.font: UIFont(name: "FontAwesome5Pro-Solid", size: 20)!], for: .highlighted)
        return b
    }

    var rightButton: UIBarButtonItem {
        let b = UIBarButtonItem(title: "cogs", style: .plain, target: self, action: #selector(settings))
        b.setTitleTextAttributes([.font: UIFont(name: "FontAwesome5Pro-Solid", size: 20)!], for: .normal)
        b.setTitleTextAttributes([.font: UIFont(name: "FontAwesome5Pro-Solid", size: 20)!], for: .highlighted)
        return b
    }
    
    override init(_ stepper: Stepper, _ services: AppServices) {
        model = StreamModel(services)
        settingsService = services.settings
        
        let actions = [
            UIAction(title: "All Chat") { _ in },
            UIAction(title: "LiveTL Mode") { _ in }
        ]
        chatControl = UISegmentedControl(frame: .zero, actions: actions)
        chatControl.selectedSegmentIndex = 0
        
        super.init(stepper, services)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        settingsService.spotlightUser = nil
        
        model.output.errorRelay.compactMap { $0 }.subscribe(onNext: handle(_:)).disposed(by: bag)
        errorRelay.compactMap { $0 }.subscribe(onNext: handle(_:)).disposed(by: bag)
        
        navigationItem.leftBarButtonItem = leftButton
        navigationItem.rightBarButtonItem = rightButton
        
        view.backgroundColor = .systemBackground
        
        model.output.videoDriver.compactMap { $0 }
            .drive(onNext: { item in
                DispatchQueue.main.async { [self] in
                    let m3u8 = try! M3U8PlaylistModel(url: item.streamURL!)
                    var streamURL: URL? = item.streamURL!
                    videoID = item.identifier
                    
                    waitRoomView.isHidden = true
                    
                    for i in 0 ..< m3u8.masterPlaylist.xStreamList.count {
                        if m3u8.masterPlaylist.xStreamList.xStreamInf(at: i)?.resolution == YouTubeResolution.auto.mediaResolution {
                            streamURL = m3u8.masterPlaylist.xStreamList.xStreamInf(at: i).m3u8URL()
                        }
                    }
                    let playerItem = AVPlayerItem(url: streamURL!)
                    
                    player?.replaceCurrentItem(with: playerItem)
                    videoPlayer.player = player
                    player?.play()
                    
                    let time = CMTime(seconds: 0.25, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
                    videoPlayer.player?.addPeriodicTimeObserver(forInterval: time, queue: .main) { time in
                        model.input.timeControl.accept((time.seconds, item.identifier))
                    }
                }
            }).disposed(by: bag)
        videoView.addSubview(videoPlayer.view)
        addChild(videoPlayer)
        view.addSubview(videoView)
        videoPlayer.didMove(toParent: self)
        
        waitRoomTextView.backgroundColor = .black.withAlphaComponent(0.8)
        waitRoomTextView.layer.cornerRadius = 10
        waitRoomView.contentMode = .scaleAspectFit
        waitRoomView.addSubview(waitRoomTextView)
        videoView.addSubview(waitRoomView)
        
        caption.textColor = .white
        caption.font = .systemFont(ofSize: captionFontSize)
        caption.textAlignment = .center
        caption.backgroundColor = .black.withAlphaComponent(0.8)
        caption.numberOfLines = 0
        caption.lineBreakMode = .byWordWrapping
        caption.text = ""
        
        if !settingsService.captions {
            caption.isHidden = true
        }
        
        model.output.captionDriver.drive(onNext: { [self] item in
            if item.last != nil {
                // remove emotes
                var fullMessage = String()
                
                for m in item.last!.displayMessage {
                    switch m {
                    case .text(let s):
                        fullMessage.append(s)
                    case .emote:
                        continue
                    }
                }
                
                // calculate view size
                let nsText = fullMessage as NSString
                
                let textSize = nsText.boundingRect(with: videoPlayer.view.frame.size, options: [.truncatesLastVisibleLine, .usesLineFragmentOrigin], attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: captionFontSize)], context: nil).size
                caption.frame.size = textSize
                
                caption.align(.underCentered, relativeTo: videoPlayer.view, padding: ((videoPlayer.view.height / 8) * (-1)) - caption.height, width: caption.width, height: caption.height)
                
                // update text
                caption.text = fullMessage
            }
        }).disposed(by: bag)
        videoPlayer.contentOverlayView?.addSubview(caption)
        
        chatControl.rx.value.compactMap { ChatControlType(rawValue: $0) }
            .bind(to: model.input.chatControl)
            .disposed(by: bag)
        view.addSubview(chatControl)
        
        model.output.chatDriver.drive(chatTable.rx.items(cellIdentifier: ChatCell.identifier, cellType: ChatCell.self)) { _, item, cell in
            let ts = (self.model as? StreamModel)?.services.settings.timestamps ?? true
            cell.configure(item, useTimestamps: ts)
        }.disposed(by: bag)
        model.output.loadingDriver.drive(chatTable.loadingRelay).disposed(by: bag)
        model.output.emptyDriver.drive(chatTable.emptyRelay).disposed(by: bag)
        chatTable.rx.setDelegate(model as! StreamModel).disposed(by: bag)
        view.addSubview(chatTable)
        
        do {
            try sharedAudio.setCategory(.playback, mode: .moviePlayback)
            try sharedAudio.setActive(true)
        } catch {
            print("AVAudioSession error: \(error.localizedDescription)")
            errorRelay.accept(NSError(domain: "app.livetl.ios", code: 100, userInfo: [
                NSLocalizedDescriptionKey: Bundle.main.localizedString(forKey: "Audio will only play if device in not in silent mode.", value: "Audio will only play if device in not in silent mode.", table: "Localizeable")
            ]))
        }
    }
    
    @objc func load(_ id: String) {
        model.input.load(id)
        videoID = id
    }
    
    @objc func closeStream() {
        videoPlayer.player?.pause()
        videoPlayer.player = nil
        player = nil
        settingsService.spotlightUser = nil
        stepper.steps.accept(AppStep.home)
    }
    
    @objc func settings() {
        stepper.steps.accept(AppStep.settings)
    }
    
    override func handle(_ error: Error) {
        let nserror = error as NSError
        
        if nserror.code == -2, waitRoom == false {
            waitRoom = true
            waitRoomView.kf.setImage(with: URL(string: "https://i.ytimg.com/vi/\(videoID)/maxresdefault.jpg"), options: [.cacheOriginalImage]) { result in
                switch result {
                case .failure: do {
                    self.waitRoomView.kf.setImage(with: URL(string: "https://i.ytimg.com/vi/\(self.videoID)/mqdefault.jpg"), options: [.cacheOriginalImage])
                    }
                case .success:
                    break
                }
            }
            // Get Timestamp
            let startStringTimestamp = nserror.userInfo["startTimestamp"] as! String
            let startTimestamp = Date(timeIntervalSince1970: Double(startStringTimestamp)!)
            let interval = DateInterval(start: Date(), end: startTimestamp)
            
            // Create Countdown Timer
            let countDown = Int(interval.duration)
            Observable<Int>.timer(.seconds(0), period: .seconds(1), scheduler: MainScheduler.instance)
                .take(countDown + 1)
                .subscribe(onNext: { timePassed in
                    let count = countDown - timePassed
                    let h = String(format: "%02d", count / 3600)
                    let m = String(format: "%02d", (count % 3600) / 60)
                    let s = String(format: "%02d", (count % 3600) % 60)
                    var timer = "\(m):\(s)"
                    if h != "00" {
                        timer = "\(h):\(timer)"
                    }
                    self.waitTimeText.text = "Live in " + timer

                }, onCompleted: {
                    self.waitTimeText.text = "Waiting on stream to start"
                })
                .disposed(by: bag)
            waitTimeText.font = .systemFont(ofSize: 19)
            waitTimeText.textColor = .white
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .long
            dateFormatter.timeStyle = .medium
            dateFormatter.timeZone = .current
            dateFormatter.locale = .current
            waitTimeScheduled.text = dateFormatter.string(from: startTimestamp)
            waitTimeScheduled.font = .systemFont(ofSize: 15)
            waitTimeScheduled.textColor = .white
            
            waitRoomTextView.addSubview(waitTimeText)
            waitRoomTextView.addSubview(waitTimeScheduled)
            model.input.loadPreviewChat(videoID, duration: 0)
        }
        
        if nserror.code == -6, nserror.userInfo["consentHtmlData"] as? String != nil {
            closeStream()
            return stepper.steps.accept(AppStep.toConsent(true))
        } else if nserror.code == -2 && (nserror.localizedDescription.hasSuffix("Join this channel to get access to members-only content and other exclusive perks.") || nserror.localizedDescription == "Join this channel to get access to members-only content like this video, and other exclusive perks.") {
            if settingsService.youtubeLogin == false {
                let alert = SCLAlertView()
                alert.addButton(Bundle.main.localizedString(forKey: "Go Back", value: "Go Back", table: "Localizeable")) {
                    self.closeStream()
                }
                alert.addButton(Bundle.main.localizedString(forKey: "Sign in to YouTube", value: "Sign in to YouTube", table: "Localizeable")) {
                    self.closeStream()
                    return self.stepper.steps.accept(AppStep.toConsent(false))
                }
                alert.showInfo(Bundle.main.localizedString(forKey: "Member Only Stream", value: "Member Only Stream", table: "Localizeable"), subTitle: Bundle.main.localizedString(forKey: "It looks like you're trying to watch a member only stream. If you're already a member of this channel, you can sign into Youtube to watch it!", value: "It looks like you're trying to watch a member only stream. If you're already a member of this channel, you can sign into Youtube to watch it!", table: "Localizeable"))
            } else if settingsService.youtubeLogin == true {
                let alert = SCLAlertView()
                alert.addButton(Bundle.main.localizedString(forKey: "Go Back", value: "Go Back", table: "Localizeable")) {
                    self.closeStream()
                }
                alert.showError(Bundle.main.localizedString(forKey: "An Error Occurred", value: "An Error Occurred", table: "Localizeable"), subTitle: error.localizedDescription + " You'll need to join the channel from youtube.com or the YouTube app. If this is in error, try logging out and logging in again.")
            }
        } else if !nserror.localizedDescription.starts(with: "This live event will begin in")  {
            let alert = SCLAlertView()
            alert.addButton(Bundle.main.localizedString(forKey: "Go Back", value: "Go Back", table: "Localizeable")) {
                self.closeStream()
            }
            alert.showError(Bundle.main.localizedString(forKey: "An Error Occurred", value: "An Error Occurred", table: "Localizeable"), subTitle: error.localizedDescription)
        }
        
        // super.handle(error)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        view.bringSubviewToFront(videoView)
                
        switch UIDevice.current.model {
        case "iPhone": view.width < view.height ? iPhoneLayoutPortrait() : iPhoneLayoutLandscape()
        case "iPad": view.width < view.height ? iPadLayoutPortrait() : iPadLayoutLandscape()
            
        default: break
        }
        
        videoPlayer.view.frame = videoView.bounds
        navigationController?.setNavigationBarHidden(view.width > view.height, animated: false)
        videoPlayer.contentOverlayView?.frame = videoView.bounds
        
        let nsText = caption.text! as NSString
        let textSize = nsText.boundingRect(with: videoPlayer.view.frame.size, options: [.truncatesLastVisibleLine, .usesLineFragmentOrigin], attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: captionFontSize)], context: nil).size
        caption.frame.size = textSize
        caption.align(.underCentered, relativeTo: videoPlayer.view, padding: ((videoPlayer.view.height / 8) * (-1)) - caption.height, width: caption.width, height: caption.height)
    }
    
    func iPhoneLayoutPortrait() {
        let topHeight = (UIApplication.shared.delegate as? AppDelegate)?.topBarHeight ?? 0
        videoView.anchorAndFillEdge(.top, xPad: 0, yPad: topHeight, otherSize: 210)
        waitRoomView.fillSuperview()
        waitRoomTextView.anchorToEdge(.bottom, padding: 5, width: videoView.width - 10, height: 56)
        waitTimeText.anchorInCorner(.topLeft, xPad: 10, yPad: 5, width: waitRoomTextView.width - 10, height: 19)
        waitTimeScheduled.align(.underCentered, relativeTo: waitTimeText, padding: 5, width: waitRoomTextView.width - 10, height: 15)
        let chatTableHeight = view.height - (videoView.frame.maxY + 75)
        chatTable.anchorAndFillEdge(.bottom, xPad: 0, yPad: 20, otherSize: chatTableHeight)
        
        chatControl.align(.aboveCentered, relativeTo: chatTable, padding: 5, width: view.width - 10, height: 35)
    }

    func iPhoneLayoutLandscape() {
        videoView.anchorAndFillEdge(.left, xPad: 0, yPad: 0, otherSize: view.width * 0.65)
        waitRoomView.fillSuperview()
        waitRoomTextView.anchorToEdge(.bottom, padding: 5, width: videoView.width - 10, height: 56)
        waitTimeText.anchorInCorner(.topLeft, xPad: 10, yPad: 5, width: waitRoomTextView.width - 10, height: 19)
        waitTimeScheduled.align(.underCentered, relativeTo: waitTimeText, padding: 5, width: waitRoomTextView.width - 10, height: 15)
        
        chatTable.anchorInCorner(.bottomRight, xPad: 0, yPad: 0, width: view.width * 0.35, height: view.height - 45)
        
        let contentMarginRight = (UIApplication.shared.delegate as? AppDelegate)?.notchSize ?? 0
        chatControl.align(.aboveCentered, relativeTo: chatTable, padding: 5, width: view.width * 0.32 - contentMarginRight, height: 35)
        
    }
    
    func iPadLayoutPortrait() {
        videoView.anchorAndFillEdge(.top, xPad: 0, yPad: 0, otherSize: view.height * 0.6)
        waitRoomView.fillSuperview()
        waitRoomTextView.anchorToEdge(.bottom, padding: 5, width: videoView.width - 10, height: 56)
        waitTimeText.anchorInCorner(.topLeft, xPad: 10, yPad: 5, width: waitRoomTextView.width - 10, height: 19)
        waitTimeScheduled.align(.underCentered, relativeTo: waitTimeText, padding: 5, width: waitRoomTextView.width - 10, height: 15)
        
        chatTable.anchorAndFillEdge(.bottom, xPad: 0, yPad: 0, otherSize: view.height * 0.35)
        chatControl.align(.aboveCentered, relativeTo: chatTable, padding: 5, width: view.width - 10, height: 35)
    }

    func iPadLayoutLandscape() {
        videoView.anchorAndFillEdge(.left, xPad: 0, yPad: 0, otherSize: view.width * 0.7)
        waitRoomView.fillSuperview()
        waitRoomTextView.anchorToEdge(.bottom, padding: 5, width: videoView.width - 10, height: 56)
        waitTimeText.anchorInCorner(.topLeft, xPad: 10, yPad: 5, width: waitRoomTextView.width - 10, height: 19)
        waitTimeScheduled.align(.underCentered, relativeTo: waitTimeText, padding: 5, width: waitRoomTextView.width - 10, height: 15)
        
        chatTable.anchorInCorner(.bottomRight, xPad: 0, yPad: 0, width: view.width * 0.3, height: view.height - 85)
        chatControl.align(.aboveCentered, relativeTo: chatTable, padding: 2, width: view.width * 0.3, height: 35)
    }
}
