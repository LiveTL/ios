//
//  FilterView.swift
//  ios
//
//  Created by Andrew Glaze on 7/12/21.
//

import Foundation
import UIKit
import Eureka
import RxFlow
import RxSwift
import SwiftyUserDefaults

class FilterView: FormViewController {
    let services: AppServices
    let stepper: Stepper
    let bag = DisposeBag()
    
    
    var settings: SettingsService { services.settings }

    var rightButton: UIBarButtonItem {
        return UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(filterDone))
    }
    
    init(_ services: AppServices, stepper: Stepper) {
        self.services = services
        self.stepper = stepper
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = rightButton
        navigationItem.title = "Organization Filter"
        
        form +++ SelectableSection<ListCheckRow<Organization>>("org_filter", selectionType: .singleSelection(enableDeselection: false))
        
        for option in Organization.allCases {
            form.last! <<< ListCheckRow<Organization>(option.description){ listRow in
                listRow.title = option.description
                listRow.selectableValue = option
                if option == settings.orgFilter {
                    listRow.value = settings.orgFilter
                } else {
                    listRow.value = nil
                }
            }.onChange { row in
                if let value = row.value {
                    self.settings.orgFilter = value
                }
            }
        }
        
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func filterDone() {
        let values = form.values()
        
        if let always = values["always_users_section"] as? Array<String> {
            settings.alwaysUsers = always
        }
        if let never = values["never_users_section"] as? Array<String> {
            settings.neverUsers = never
        }
        
        stepper.steps.accept(AppStep.filterDone)
    }
}
