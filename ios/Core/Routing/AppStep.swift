//
//  AppStep.swift
//  ios
//
//  Created by Mason Phillips on 3/25/21.
//

import Foundation
import RxFlow

enum AppStep: Step {
    case home
    case view(_ id: String)
    case streamDone
    case settings, settingsDone
    case filter, filterDone
    case toConsent(_ showAlert: Bool), consentDone
}
