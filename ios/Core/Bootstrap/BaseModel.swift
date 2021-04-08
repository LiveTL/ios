//
//  BaseModel.swift
//  ios
//
//  Created by Mason Phillips on 3/25/21.
//

import Foundation
import RxCocoa
import RxSwift

class BaseModel: NSObject {
    let services: AppServices
    
    let errorRelay = BehaviorRelay<Error?>(value: nil)
    let bag = DisposeBag()
    
    init(_ services: AppServices) {
        self.services = services
    }
}
