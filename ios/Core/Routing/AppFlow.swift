//
//  AppFlow.swift
//  ios
//
//  Created by Mason Phillips on 3/25/21.
//

import UIKit
import RxCocoa
import RxFlow

class AppFlow: Flow {
    var root: Presentable {
        return rootViewController
    }
    
    let rootViewController = UINavigationController()
    let stepper  = AppStepper()
    let services = AppServices()
    
    func navigate(to step: Step) -> FlowContributors {
        guard let step = step as? AppStep else { return .none }
        
        switch step {
        case .home        : return toHome()
        case .view(let id): return toStreamView(id)
        case .settings    : return toSettings()
        case .settingsDone: return settingsDone()
        }
    }
    
    private func toHome() -> FlowContributors {
        let controller = HomeView(stepper, services)
        rootViewController.setViewControllers([controller], animated: true)
        
        return .none
    }
    private func toStreamView(_ id: String) -> FlowContributors {
        let controller = StreamView(stepper, services)
        controller.load(id)
        rootViewController.setViewControllers([controller], animated: true)
        
        return .none
    }
    private func toSettings() -> FlowContributors {
        let controller = SettingsView(services, stepper: stepper)
        let navigation = UINavigationController(rootViewController: controller)
        rootViewController.present(navigation, animated: true, completion: nil)
        
        return .none
    }
    private func settingsDone() -> FlowContributors {
        rootViewController.dismiss(animated: true, completion: nil)
        
        return .none
    }
}

class AppStepper: Stepper {
    var initialStep = AppStep.home
    var steps = PublishRelay<Step>()
    
    func readyToEmitSteps() {
        steps.accept(initialStep)
    }
}
