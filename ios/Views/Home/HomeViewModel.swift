//
//  HomeViewModel.swift
//  ios
//
//  Created by Mason Phillips on 12/30/21.
//

import UIKit
import SwiftUI

class HomeViewModel: UIHostingController<HomeView> {
    let model: HomeModel
    
    var leftButton: UIBarButtonItem = {
        let button = UIBarButtonItem(title: "user", style: .plain, target: self, action: #selector(openUser))
        button.setTitleTextAttributes([.font: UIFont(name: "FontAwesome5Pro-Solid", size: 20)!], for: .normal)
        button.setTitleTextAttributes([.font: UIFont(name: "FontAwesome5Pro-Solid", size: 20)!], for: .highlighted)
        
        return button
    }()
    
    var rightButton: UIBarButtonItem = {
        let button = UIBarButtonItem(title: "cogs", style: .plain, target: self, action: #selector(openUser))
        button.setTitleTextAttributes([.font: UIFont(name: "FontAwesome5Pro-Solid", size: 20)!], for: .normal)
        button.setTitleTextAttributes([.font: UIFont(name: "FontAwesome5Pro-Solid", size: 20)!], for: .highlighted)
        
        return button
    }()
    
    init(_ pl: String = "") {
        model = HomeModel()
        
        super.init(rootView: HomeView())
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = leftButton
        navigationItem.rightBarButtonItem = rightButton
    }
    
    @objc
    func openUser() {
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        model = HomeModel()
        super.init(coder: aDecoder)
    }
}
