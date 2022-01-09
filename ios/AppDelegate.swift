//
//  AppDelegate.swift
//  ios
//
//  Created by Mason Phillips on 12/30/21.
//

import UIKit
import FontBlaster
import RxFlow
import RxSwift

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    let coordinator = FlowCoordinator()
    let bag = DisposeBag()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FontBlaster.blast()
        
        window = UIWindow(frame: UIScreen.main.bounds)
        
        coordinator.rx.willNavigate.subscribe(onNext: { args in
            print("WN: \(args.0) -> \(args.1)")
        }).disposed(by: bag)
        coordinator.rx.didNavigate.subscribe(onNext: { args in
            print("DN: \(args.0) -> \(args.1)")
        }).disposed(by: bag)
        
        let flow = AppFlow()
        Flows.use(flow, when: .created) { [window] flowRoot in
            window?.rootViewController = flowRoot
            window?.makeKeyAndVisible()
        }
        coordinator.coordinate(flow: flow, with: flow.stepper)
        
        return true
    }
}
