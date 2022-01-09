//
//  AppFlow.swift
//  ios
//
//  Created by Mason Phillips on 12/30/21.
//

import UIKit
import RxCocoa
import RxFlow
import RxSwift

class AppFlow: Flow {
    var root: Presentable { rootViewController }
    let rootViewController = UINavigationController()
    
    let stepper = AppStepper()
    
    init() {
//        rootViewController.isNavigationBarHidden = true
    }
    
    func navigate(to step: Step) -> FlowContributors {
        guard let step = step as? AppStep else { return .none }
        
        switch step {
        case .home         : return toHome()
        case .stream(let s): return toStream(s)
        case .settings     : return toSettings()
            
        case .streamDone, .settingsDone:
            return removeView()
            
        default: return .none
        }
    }
    
    private func toHome() -> FlowContributors {
        let controller = HomeViewModel()
        rootViewController.setViewControllers([controller], animated: true)
        
        return .none
    }
    
    private func toStream(_ id: String) -> FlowContributors {
        return .none
    }
    
    private func toSettings() -> FlowContributors {
        return .none
    }
    
    private func removeView() -> FlowContributors {
        return .none
    }
}

class AppStepper: Stepper {
    let steps = PublishRelay<Step>()
    let initialStep = AppStep.home
    
    func readyToEmitSteps() {
        steps.accept(initialStep)
    }
}
