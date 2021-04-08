//
//  AppDelegate.swift
//  ios
//
//  Created by Mason Phillips on 3/24/21.
//

import UIKit
import AVKit
import FontBlaster
import RxCocoa
import RxFlow
import RxSwift

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    let coordinator = FlowCoordinator()
    let bag = DisposeBag()
    
    var topBarHeight: CGFloat {
        var height: CGFloat = 0
        height += window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
        if let root = window?.rootViewController as? UINavigationController {
            height += root.navigationBar.frame.height
        }
        return height
    }
    var notchSize: CGFloat {
        let inset = window?.windowScene?.windows.filter { $0.isKeyWindow }.first?.safeAreaInsets
        return (UIDevice.current.orientation == .landscapeRight ? inset?.right ?? 0 : 0)
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FontBlaster.blast()
        
        window = UIWindow(frame: UIScreen.main.bounds)
        
        let flow = AppFlow()
        Flows.use(flow, when: .created) { [window] root in
            window?.rootViewController = root
            window?.makeKeyAndVisible()
        }
        
        coordinator.rx.willNavigate.subscribe(onNext: { args in
            print("WN \(args.0) -> \(args.1)")
        }).disposed(by: bag)
        coordinator.rx.didNavigate.subscribe(onNext: { args in
            print("DN \(args.0) -> \(args.1)")
        }).disposed(by: bag)

        coordinator.coordinate(flow: flow, with: flow.stepper)
        
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        switch url.scheme {
        case "livetl-translate":
            let id = url.path.replacingOccurrences(of: "/", with: "")
            coordinator.navigate(to: AppStep.view(id))
                
            return true
            
        default: return false
        }
    }
}
