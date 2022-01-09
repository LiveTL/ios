//
//  AppStep.swift
//  ios
//
//  Created by Mason Phillips on 12/30/21.
//

import RxFlow

enum AppStep: Step {
    case onboarding
    
    
    case home
    case stream(_ id: String), streamDone
    case settings, settingsDone
}
