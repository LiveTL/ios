//
//  StreamView.swift
//  ios
//
//  Created by Mason Phillips on 3/25/21.
//

import UIKit
import AVKit
import RxCocoa
import RxFlow
import RxSwift
import Neon
import SCLAlertView

class StreamView: BaseController {
    let videoPlayer = AVPlayerViewController()
    let videoView   = UIView(frame: .zero)
    
    let chatTable = ChatTable(frame: .zero, style: .plain)
    let chatControl: UISegmentedControl
    
    let model: StreamModelType
    
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
        
        let actions = [
            UIAction(title: "All Chat") { _ in return },
            UIAction(title: "LiveTL Mode") { _ in return }
        ]
        chatControl = UISegmentedControl(frame: .zero, actions: actions)
        chatControl.selectedSegmentIndex = 0
        
        super.init(stepper, services)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        model.output.errorRelay.compactMap { $0 }.subscribe(onNext: handle(_:)).disposed(by: bag)
        errorRelay.compactMap { $0 }.subscribe(onNext: handle(_:)).disposed(by: bag)
        
        navigationItem.leftBarButtonItem = leftButton
        navigationItem.rightBarButtonItem = rightButton
        
        view.backgroundColor = .systemBackground
        
        model.output.videoDriver.compactMap { $0 }
            .drive(onNext: { item in
                DispatchQueue.main.async {
                    let player = AVPlayer(playerItem: AVPlayerItem(url: item.streamURL!))
                    self.videoPlayer.player = player
                    player.play()
                    
                    let time = CMTime(seconds: 0.25, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
                    self.videoPlayer.player?.addPeriodicTimeObserver(forInterval: time, queue: .main) { time in
                        self.model.input.timeControl.accept((time.seconds, item.identifier))
                    }
                }
            }).disposed(by: bag)
        videoView.addSubview(videoPlayer.view)
        addChild(videoPlayer)
        view.addSubview(videoView)
        videoPlayer.didMove(toParent: self)
        
        chatControl.rx.value.compactMap { ChatControlType(rawValue: $0) }
            .bind(to: model.input.chatControl)
            .disposed(by: bag)
        view.addSubview(chatControl)
        
        model.output.chatDriver.drive(chatTable.rx.items(cellIdentifier: ChatCell.identifier, cellType: ChatCell.self)) { index, item, cell in
            cell.configure(item)
        }.disposed(by: bag)
        model.output.loadingDriver.drive(chatTable.loadingRelay).disposed(by: bag)
        model.output.emptyDriver.drive(chatTable.emptyRelay).disposed(by: bag)
        chatTable.rx.setDelegate(model as! StreamModel).disposed(by: bag)
        view.addSubview(chatTable)
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
        } catch {
            print("AVAudioSession error: \(error.localizedDescription)")
            errorRelay.accept(NSError(domain: "app.livetl.ios", code: 100, userInfo: [
                NSLocalizedDescriptionKey: "Audio will only play if device in not in silent mode."
            ]))
        }
    }
    
    func load(_ id: String) {
        model.input.load(id)
    }
    
    @objc func closeStream() {
        videoPlayer.player?.pause()
        videoPlayer.player = nil
        stepper.steps.accept(AppStep.home)
    }
    
    @objc func settings() {
        stepper.steps.accept(AppStep.settings)
    }
    
    override func handle(_ error: Error) {
        let alert = SCLAlertView()
        alert.addButton("Go Back") {
            self.closeStream()
        }
        alert.showError("An Error Occurred", subTitle: error.localizedDescription)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        view.bringSubviewToFront(videoView)
        
        switch UIDevice.current.model {
        case "iPhone": view.width < view.height ? iPhoneLayoutPortrait() : iPhoneLayoutLandscape()
            
        default: break
        }        
    }
    
    func iPhoneLayoutPortrait() {
        navigationController?.setNavigationBarHidden(false, animated: false)
        let topHeight = (UIApplication.shared.delegate as? AppDelegate)?.topBarHeight ?? 0
        videoView.anchorAndFillEdge(.top, xPad: 0, yPad: topHeight, otherSize: 210)
        videoPlayer.view.frame = videoView.bounds
        
        let chatTableHeight = view.height - (videoView.frame.maxY + 75)
        chatTable.anchorAndFillEdge(.bottom, xPad: 0, yPad: 20, otherSize: chatTableHeight)
        
        chatControl.align(.aboveCentered, relativeTo: chatTable, padding: 5, width: view.width - 10, height: 35)
    }
    func iPhoneLayoutLandscape() {
        navigationController?.setNavigationBarHidden(true, animated: false)
        videoView.anchorAndFillEdge(.left, xPad: 0, yPad: 0, otherSize: view.width * 0.65)
        videoPlayer.view.frame = videoView.bounds
        
        chatTable.anchorInCorner(.bottomRight, xPad: 0, yPad: 0, width: view.width * 0.35, height: view.height - 45)
        
        let contentMarginRight = (UIApplication.shared.delegate as? AppDelegate)?.notchSize ?? 0
        chatControl.align(.aboveCentered, relativeTo: chatTable, padding: 5, width: view.width * 0.32 - contentMarginRight, height: 35)
    }
}
