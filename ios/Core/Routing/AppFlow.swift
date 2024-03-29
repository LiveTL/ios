//
//  AppFlow.swift
//  ios
//
//  Created by Mason Phillips on 3/25/21.
//

import UIKit
import RxCocoa
import RxFlow
import Kingfisher

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
        case .home                   : return toHome()
        case .view(let id)           : return toStreamView(id)
        case .streamDone             : return streamViewDone()
        case .settings               : return toSettings()
        case .settingsDone           : return settingsDone()
        case .toConsent(let showAlert): return toConsent(showAlert)
        case .consentDone            : return toConsentDone()
        case .filter                 : return toFilter()
        case .filterDone             : return filterDone()
        }
    }
    
    private func toHome() -> FlowContributors {
        let controller = HomeView(stepper, services)
        rootViewController.pushViewController(controller, animated: true)
        //rootViewController.setViewControllers([controller], animated: true)

        return .none
    }
    private func toStreamView(_ id: String) -> FlowContributors {
        let controller = StreamView(stepper, services)
        controller.load(id)
        KingfisherManager.shared.cache.clearMemoryCache()
        rootViewController.pushViewController(controller, animated: true)
        
        return .none
    }
    private func streamViewDone() -> FlowContributors {
        rootViewController.popViewController(animated: true)
        
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
    private func toConsent(_ showAlert: Bool) -> FlowContributors {
        //NOTE - ConsentViewController does not work correctly in simulator, use a real device!
        let controller = ConsentViewController(stepper, services, showAlert: showAlert)
        let navigation = UINavigationController(rootViewController: controller)
        
        rootViewController.present(navigation, animated: true) {
            controller.consentFunction()
        }
        
        return .end(forwardToParentFlowWithStep: AppStep.home)
    }
    private func toConsentDone() -> FlowContributors {
        rootViewController.dismiss(animated: true)
        return .none
    }
    private func toFilter() -> FlowContributors {
        let controller = FilterView(services, stepper: stepper)
        let navigation = UINavigationController(rootViewController: controller)
        rootViewController.present(navigation, animated: true, completion: nil)
        
        return .none
    }
    private func filterDone() -> FlowContributors {
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
