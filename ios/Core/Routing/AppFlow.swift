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
        case .home                    : return toHome()
        case .view(let id)            : return toStreamView(id)
        case .settings                : return toSettings()
        case .settingsDone            : return settingsDone()
        case .toConsent(let htmlData) : return toConsent(htmlData)
        case .filter                  : return toFilter()
        case .filterDone              : return filterDone()
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
        
        if let homeView = rootViewController.topViewController as? HomeView {
            homeView.doRefresh()
        }
        
        return .none
    }
    private func toConsent(_ htmlData: String) -> FlowContributors {
        //NOTE - ConsentViewController does not work correctly in simulator, use a real device!
        let controller = ConsentViewController()
        controller.htmlData = htmlData
        let navigation = UINavigationController(rootViewController: controller)
        rootViewController.present(navigation, animated: true, completion: nil)
        
        return .end(forwardToParentFlowWithStep: AppStep.home)
    }
    private func toFilter() -> FlowContributors {
        let controller = FilterView(services, stepper: stepper)
        let navigation = UINavigationController(rootViewController: controller)
        rootViewController.present(navigation, animated: true, completion: nil)
        
        return .none
    }
    private func filterDone() -> FlowContributors {
        rootViewController.dismiss(animated: true, completion: nil)
        let homeView = rootViewController.topViewController as! HomeView
        homeView.doRefresh()
        
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
