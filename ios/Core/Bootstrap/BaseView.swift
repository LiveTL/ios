//
//  BaseView.swift
//  ios
//
//  Created by Mason Phillips on 3/25/21.
//

import UIKit
import RxCocoa
import RxFlow
import RxSwift
import SCLAlertView

class BaseController: UIViewController {
    let stepper: Stepper
    
    let errorRelay = BehaviorRelay<Error?>(value: nil)
    let bag = DisposeBag()
    
    init(_ stepper: Stepper, _ services: AppServices) {
        self.stepper = stepper
        
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        errorRelay.compactMap { $0 }.subscribe(onNext: handle(_:)).disposed(by: bag)
    }
    
    func handle(_ error: Error) {
        
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError()
    }
}
