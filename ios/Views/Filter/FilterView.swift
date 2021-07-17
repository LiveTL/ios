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
        
        
        var section = SelectableSection<ListCheckRow<Organization>>("Select Organization", selectionType: .singleSelection(enableDeselection: false)) { $0.tag = "orgFilter" }
        section += Organization.allCases.map { org -> ListCheckRow<Organization> in
            return ListCheckRow<Organization>(org.rawValue) { row in
                row.title = org.description
                row.selectableValue = org
                
                if org == self.settings.orgFilter {
                    row.value = org
                } else {
                    row.value = nil
                }
            }.onChange { row in
                if let value = row.value { self.settings.orgFilter = value }
            }
        }
        
        form +++ section
    }
    
    @objc func filterDone() {
        stepper.steps.accept(AppStep.filterDone)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
}
